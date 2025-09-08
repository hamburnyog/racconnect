import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/profile_model.dart';
import 'package:racconnect/data/models/travel_model.dart';
import 'package:racconnect/data/models/user_model.dart';
import 'package:racconnect/data/repositories/auth_repository.dart';
import 'package:racconnect/logic/cubit/travel_cubit.dart';
import 'package:racconnect/utility/constants.dart';
import 'package:table_calendar/table_calendar.dart';

String? getPocketBaseFileUrl(String? filename, String? recordId) {
  if (filename == null ||
      filename.isEmpty ||
      recordId == null ||
      recordId.isEmpty) {
    return null;
  }
  return '$serverUrl/api/files/_pb_users_auth_/$recordId/$filename';
}

class TravelForm extends StatefulWidget {
  final TravelModel? travelModel;
  const TravelForm({this.travelModel, super.key});

  @override
  State<TravelForm> createState() => _TravelFormState();
}

class _TravelFormState extends State<TravelForm> {
  final TextEditingController soNumberController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  DateTime _focusedDay = DateTime.now();
  final Set<DateTime> _selectedDates = <DateTime>{};
  List<UserModel> allUsers = [];
  List<ProfileModel> allProfiles = [];
  List<ProfileModel> selectedEmployees = [];
  List<ProfileModel> filteredProfiles = [];
  bool isLoadingProfiles = false;

  @override
  void initState() {
    super.initState();
    if (widget.travelModel != null) {
      soNumberController.text = widget.travelModel!.soNumber;
      _selectedDates.addAll(widget.travelModel!.specificDates);
      // Selected employees will be loaded after profiles are fetched
    }
    _loadUsers();
    searchController.addListener(() {
      filterProfiles();
    });
  }

  void filterProfiles() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredProfiles =
          allProfiles.where((profile) {
            final fullName =
                '${profile.firstName} ${profile.middleName ?? ''} ${profile.lastName}'
                    .toLowerCase();
            final sectionCode = profile.sectionCode?.toLowerCase() ?? '';
            final employeeNumber = profile.employeeNumber?.toLowerCase() ?? '';

            return fullName.contains(query) ||
                sectionCode.contains(query) ||
                employeeNumber.contains(query);
          }).toList();
    });
  }

  Future<void> _loadUsers() async {
    setState(() {
      isLoadingProfiles = true;
    });

    try {
      final authRepository = AuthRepository();
      final users = await authRepository.getUsers();

      // Filter profiles to only include those with a role (not null)
      allUsers =
          users
              .where(
                (user) =>
                    user.role != null &&
                    user.role!.isNotEmpty &&
                    user.profile != null &&
                    user.profile!.employmentStatus != 'Resigned' &&
                    user.profile!.employmentStatus != 'Retired' &&
                    user.profile!.employeeNumber != null &&
                    user.profile!.employeeNumber!.isNotEmpty,
              )
              .toList();

      allProfiles = allUsers.map((user) => user.profile!).toList();

      // If editing, match employee numbers to profiles
      if (widget.travelModel != null) {
        final employeeNumbers = widget.travelModel!.employeeNumbers;
        selectedEmployees =
            allProfiles
                .where(
                  (profile) =>
                      profile.employeeNumber != null &&
                      employeeNumbers.contains(profile.employeeNumber),
                )
                .toList();
      }

      if (mounted) {
        setState(() {
          isLoadingProfiles = false;
          filteredProfiles = allProfiles;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingProfiles = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading employees: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void addTravel() {
    if (formKey.currentState!.validate()) {
      context.read<TravelCubit>().addTravel(
        soNumber: soNumberController.text,
        employeeNumbers:
            selectedEmployees.map((e) => e.employeeNumber!).toList(),
        specificDates: _selectedDates.toList(),
      );
      Navigator.of(context).pop();
    }
  }

  void saveTravel() {
    if (formKey.currentState!.validate()) {
      context.read<TravelCubit>().updateTravel(
        id: widget.travelModel!.id!,
        soNumber: soNumberController.text,
        employeeNumbers:
            selectedEmployees.map((e) => e.employeeNumber!).toList(),
        specificDates: _selectedDates.toList(),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    soNumberController.dispose();
    searchController.dispose();
    formKey.currentState?.dispose();
    super.dispose();
  }

  void _toggleEmployeeSelection(ProfileModel profile) {
    setState(() {
      if (selectedEmployees.contains(profile)) {
        selectedEmployees.remove(profile);
      } else {
        selectedEmployees.add(profile);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Text(
                          widget.travelModel == null
                              ? 'New Travel'
                              : 'Edit Travel',
                          style: const TextStyle(
                            fontSize: 30,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Center(
                          child: SvgPicture.asset(
                            'assets/images/travel.svg',
                            height: 100,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: soNumberController,
                maxLength: 50,
                keyboardType: TextInputType.text,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Special Order Number is required';
                  }
                  return null;
                },
                onFieldSubmitted:
                    (_) =>
                        widget.travelModel == null ? addTravel() : saveTravel(),
                decoration: const InputDecoration(
                  labelText: 'Special Order Number',
                  hintText: 'Enter the Special Order number',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FormField<Set<DateTime>>(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select at least one date';
                  }
                  return null;
                },
                initialValue: _selectedDates,
                builder: (FormFieldState<Set<DateTime>> state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_selectedDates.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 8.0,
                                runSpacing: 4.0,
                                alignment: WrapAlignment.start,
                                children:
                                    _selectedDates.map((date) {
                                      return Chip(
                                        label: Text(
                                          DateFormat(
                                            'MMM d, yyyy',
                                          ).format(date),
                                        ),
                                        backgroundColor:
                                            Theme.of(context).primaryColor,
                                        labelStyle: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        deleteIconColor: Colors.white,
                                        onDeleted: () {
                                          setState(() {
                                            _selectedDates.remove(date);
                                            state.didChange(_selectedDates);
                                          });
                                        },
                                      );
                                    }).toList(),
                              ),
                            ),
                          ],
                        ),
                      TableCalendar(
                        firstDay: DateTime.now().subtract(
                          const Duration(days: 365),
                        ),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: _focusedDay,
                        calendarFormat: CalendarFormat.month,
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                        availableGestures: AvailableGestures.horizontalSwipe,
                        onHeaderTapped: (focusedDay) {
                          setState(() {
                            _focusedDay = DateTime.now();
                          });
                        },
                        selectedDayPredicate: (day) {
                          return _selectedDates.any(
                            (selectedDay) => isSameDay(selectedDay, day),
                          );
                        },
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _focusedDay = focusedDay;
                            if (_selectedDates.any(
                              (date) => isSameDay(date, selectedDay),
                            )) {
                              _selectedDates.removeWhere(
                                (date) => isSameDay(date, selectedDay),
                              );
                            } else {
                              _selectedDates.add(selectedDay);
                            }
                            state.didChange(_selectedDates);
                          });
                        },
                        onPageChanged: (focusedDay) {
                          _focusedDay = focusedDay;
                        },
                        calendarBuilders: CalendarBuilders(
                          selectedBuilder: (context, date, _) {
                            return Container(
                              margin: const EdgeInsets.all(4.0),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${date.day}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          },
                          todayBuilder: (context, date, _) {
                            return Container(
                              margin: const EdgeInsets.all(4.0),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${date.day}',
                                style: const TextStyle(color: Colors.black),
                              ),
                            );
                          },
                        ),
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            state.errorText!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              FormField<List<ProfileModel>>(
                validator: (value) {
                  if (selectedEmployees.isEmpty) {
                    return 'Please select at least one employee';
                  }
                  return null;
                },
                builder: (FormFieldState<List<ProfileModel>> state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (selectedEmployees.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 8.0,
                                runSpacing: 4.0,
                                alignment: WrapAlignment.start,
                                children:
                                    selectedEmployees.map((employee) {
                                      return Chip(
                                        label: Text(
                                          '${employee.lastName}, ${employee.firstName.isNotEmpty ? employee.firstName[0] : ''}.'
                                              .toUpperCase(),
                                        ),
                                        backgroundColor:
                                            Theme.of(context).primaryColor,
                                        labelStyle: const TextStyle(
                                          color: Colors.white,
                                        ),
                                        deleteIconColor: Colors.white,
                                        onDeleted: () {
                                          setState(() {
                                            selectedEmployees.remove(employee);
                                          });
                                        },
                                      );
                                    }).toList(),
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          labelText:
                              'Search by employee number, name or section',
                          hintText: 'Enter name, section, or employee number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (isLoadingProfiles)
                        const Center(child: CircularProgressIndicator())
                      else ...[
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            itemCount: filteredProfiles.length,
                            itemBuilder: (context, index) {
                              final profile = filteredProfiles[index];
                              final user = allUsers.firstWhere(
                                (user) => user.profile == profile,
                              );
                              final isSelected = selectedEmployees.contains(
                                profile,
                              );
                              final avatarUrl = getPocketBaseFileUrl(
                                user.avatar,
                                user.id,
                              );
                              return CheckboxListTile(
                                value: isSelected,
                                onChanged: (value) {
                                  _toggleEmployeeSelection(profile);
                                },
                                secondary: CircleAvatar(
                                  backgroundImage:
                                      avatarUrl != null
                                          ? NetworkImage(avatarUrl)
                                          : null,
                                  child:
                                      avatarUrl == null
                                          ? Text(
                                            profile.firstName.isNotEmpty
                                                ? profile.firstName[0]
                                                : ' ',
                                          )
                                          : null,
                                ),
                                title: Text(
                                  '${profile.employeeNumber} - ${profile.lastName}, ${profile.firstName.isNotEmpty ? profile.firstName[0] : ''}.'
                                      .toUpperCase(),
                                  style: const TextStyle(fontSize: 14),
                                ),
                                subtitle: Text(
                                  'Section: ${profile.sectionCode}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              );
                            },
                          ),
                        ),
                        if (state.hasError)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              state.errorText!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed:
                      widget.travelModel == null ? addTravel : saveTravel,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          widget.travelModel == null
                              ? 'Add Travel'
                              : 'Save Changes',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
