import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/leave_model.dart';
import 'package:racconnect/data/models/profile_model.dart';
import 'package:racconnect/logic/cubit/leave_cubit.dart';
import 'package:racconnect/presentation/widgets/user_multi_select.dart';
import 'package:table_calendar/table_calendar.dart';

class LeaveForm extends StatefulWidget {
  final LeaveModel? leaveModel;
  const LeaveForm({this.leaveModel, super.key});

  @override
  State<LeaveForm> createState() => _LeaveFormState();
}

class _LeaveFormState extends State<LeaveForm> {
  TextEditingController leaveTypeController = TextEditingController();
  TextEditingController customLeaveTypeController = TextEditingController();
  final List<ProfileModel> _selectedEmployees = [];
  DateTime _focusedDay = DateTime.now();
  final Set<DateTime> _selectedDates = <DateTime>{};
  final formKey = GlobalKey<FormState>();
  bool _showCustomLeaveField = false;

  final List<String> leaveTypes = [
    'Sick Leave',
    'Vacation Leave',
    'Maternity Leave',
    'Paternity Leave',
    'Special Privilege Leave',
    'Solo Parent Leave',
    'Study Leave',
    'Adoption Leave',
    '10-Day VAWC Leave',
    'Mandatory/Forced Leave',
    'Rehabilitation Privilege',
    'Leave Benefits for Women',
    'Emergency (Calamity) Leave',
    'Compensatory Time-off',
    'Others',
  ];

  void addLeave() {
    if (formKey.currentState!.validate()) {
      String leaveType = leaveTypeController.text.trim();
      
      // Handle custom leave type when 'Others' is selected
      if (leaveType == 'Others' && customLeaveTypeController.text.trim().isNotEmpty) {
        leaveType = customLeaveTypeController.text.trim();
      } else if (leaveType == 'Compensatory Time-off') {
        // Map display text to storage value for CTO
        leaveType = 'CTO';
      }
      
      context.read<LeaveCubit>().addLeave(
        type: leaveType,
        specificDates: _selectedDates.toList(),
        employeeNumbers:
            _selectedEmployees.map((e) => e.employeeNumber!).toList(),
      );
      Navigator.of(context).pop();
    }
  }

  void saveLeave() {
    if (formKey.currentState!.validate()) {
      final leaveId = widget.leaveModel?.id ?? '';
      String leaveType = leaveTypeController.text.trim();
      
      // Handle custom leave type when 'Others' is selected
      if (leaveType == 'Others' && customLeaveTypeController.text.trim().isNotEmpty) {
        leaveType = customLeaveTypeController.text.trim();
      } else if (leaveType == 'Compensatory Time-off') {
        // Map display text to storage value for CTO
        leaveType = 'CTO';
      }
      
      context.read<LeaveCubit>().updateLeave(
        id: leaveId,
        type: leaveType,
        specificDates: _selectedDates.toList(),
        employeeNumbers:
            _selectedEmployees.map((e) => e.employeeNumber!).toList(),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.leaveModel != null) {
      String leaveType = widget.leaveModel!.type;
      // Check if this is a custom leave type (not in our predefined list)
      if (!leaveTypes.contains(leaveType) && leaveType != 'CTO') {
        // This is a custom leave type saved as "Others"
        customLeaveTypeController.text = leaveType; // Store the custom type in the text field
        _showCustomLeaveField = true;
        leaveTypeController.text = 'Others';
      } else {
        // Map stored CTO value to display value
        leaveTypeController.text = widget.leaveModel!.type == 'CTO' 
            ? 'Compensatory Time-off' 
            : widget.leaveModel!.type;
        _showCustomLeaveField = (leaveTypeController.text == 'Others');
      }
      _selectedDates.addAll(widget.leaveModel!.specificDates);
      if (widget.leaveModel!.specificDates.isNotEmpty) {
        _focusedDay = widget.leaveModel!.specificDates.first;
      }
    }
  }

  @override
  void dispose() {
    leaveTypeController.dispose();
    formKey.currentState?.dispose();
    super.dispose();
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
                          widget.leaveModel == null
                              ? 'New Leave'
                              : 'Edit Leave',
                          style: const TextStyle(
                            fontSize: 30,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Center(
                          child: SvgPicture.asset(
                            'assets/images/calendar.svg',
                            height: 100,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              DropdownButtonFormField<String>(
                initialValue:
                    leaveTypeController.text.isEmpty
                        ? null
                        : leaveTypeController.text,
                items:
                    leaveTypes.map((String type) {
                      return DropdownMenuItem<String>(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a leave type';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      leaveTypeController.text = value;
                      _showCustomLeaveField = (value == 'Others');
                      // Clear custom text if switching away from Others
                      if (value != 'Others') {
                        customLeaveTypeController.clear();
                      }
                    });
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Leave Type',
                  hintText: 'Select leave type',
                  border: OutlineInputBorder(),
                ),
              ),
              if (_showCustomLeaveField)
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: TextFormField(
                    controller: customLeaveTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Specify Leave Type',
                      hintText: 'Enter custom leave type',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (_showCustomLeaveField && (value == null || value.isEmpty)) {
                        return 'Please specify the leave type';
                      }
                      return null;
                    },
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
              UserMultiSelect(
                selectedEmployees: _selectedEmployees,
                initialEmployeeNumbers: widget.leaveModel?.employeeNumbers,
                onSelectionChanged: (selected) {
                  setState(() {
                    // No need to do anything here as the widget handles its own state
                  });
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
                  onPressed: widget.leaveModel == null ? addLeave : saveLeave,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          widget.leaveModel == null
                              ? 'Add Leave'
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
