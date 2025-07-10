import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:racconnect/data/models/profile_model.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';
import 'package:racconnect/logic/cubit/profile_cubit.dart';
import 'package:racconnect/presentation/widgets/leave_card.dart';
import 'package:racconnect/utility/constants.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late TextEditingController employeeNumberController;
  late TextEditingController firstNameController;
  late TextEditingController middleNameController;
  late TextEditingController lastNameController;
  late TextEditingController birthdateController;
  late TextEditingController genderController;
  late TextEditingController positionController;
  late TextEditingController employmentStatusController;

  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> _leaveCredits = {};
  ProfileModel? profile;
  String emailAddress = '';
  List<Map<String, String>> sectionOptions = [];
  String? sectionId;

  @override
  void initState() {
    super.initState();
    loadProfile();
    loadSections();
  }

  @override
  void dispose() {
    employeeNumberController.dispose();
    firstNameController.dispose();
    middleNameController.dispose();
    lastNameController.dispose();
    birthdateController.dispose();
    genderController.dispose();
    positionController.dispose();
    employmentStatusController.dispose();
    super.dispose();
  }

  Future<void> loadSections() async {
    try {
      final response = await http.get(
        Uri.parse('$serverUrl/api/collections/sections/records'),
      );
      if (response.statusCode == 200) {
        final List records = jsonDecode(response.body)['items'];

        setState(() {
          sectionOptions =
              records.map<Map<String, String>>((e) {
                return {'id': e['id'], 'name': e['name']};
              }).toList();

          if (profile?.section != null) {
            final match = sectionOptions.firstWhere(
              (opt) => opt['id'] == profile!.section,
              orElse: () => {},
            );
            sectionId = match['id'];
          }
        });
      } else {
        debugPrint('Failed to load sections');
      }
    } catch (e) {
      debugPrint('Error fetching sections: $e');
    }
  }

  Future<void> loadProfile() async {
    AuthSignedIn signedIn = context.read<AuthCubit>().state as AuthSignedIn;
    final p = signedIn.user.profile;

    setState(() {
      emailAddress = signedIn.user.email;
      profile = p;
      sectionId = p?.section;

      employeeNumberController = TextEditingController(
        text: p?.employeeNumber ?? '',
      );
      firstNameController = TextEditingController(text: p?.firstName ?? '');
      middleNameController = TextEditingController(text: p?.middleName ?? '');
      lastNameController = TextEditingController(text: p?.lastName ?? '');
      birthdateController = TextEditingController(
        text: p != null ? DateFormat('yyyy-MM-dd').format(p.birthdate) : '',
      );
      genderController = TextEditingController(text: p?.gender ?? '');
      positionController = TextEditingController(text: p?.position ?? '');
      employmentStatusController = TextEditingController(
        text: p?.employmentStatus ?? '',
      );

      _leaveCredits = {
        'SL': p?.sl ?? 0,
        'VL': p?.vl ?? 0,
        'SPL': p?.spl ?? 0,
        'CTO': p?.cto ?? 0,
      };
    });
  }

  void saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    final birthdate = DateTime.tryParse(birthdateController.text);
    if (birthdate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid birthdate format')));
      return;
    }

    final profileCubit = context.read<ProfileCubit>();
    final authCubit = context.read<AuthCubit>();
    final authState = authCubit.state;

    if (authState is! AuthSignedIn) return;

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirm Update'),
            content: const Text(
              'Saving your profile will log you out to refresh permissions. Continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();

                  await profileCubit.saveProfile(
                    id: profile?.id,
                    employeeNumber: employeeNumberController.text.trim(),
                    firstName: firstNameController.text.trim(),
                    middleName: middleNameController.text.trim(),
                    lastName: lastNameController.text.trim(),
                    birthdate: birthdate,
                    gender: genderController.text,
                    employmentStatus: employmentStatusController.text,
                    position: positionController.text.trim(),
                    sectionId: sectionId ?? '',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: Size(100, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  elevation: 0,
                ),
                child: const Text('Yes, Save & Logout'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isSmallScreen = width < 600;

    return BlocListener<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is SaveProfileSuccess) {
          context.read<AuthCubit>().signOut();
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          children: [
            Card(
              color: Theme.of(context).primaryColor,
              child: ListTile(
                minTileHeight: 70,
                leading: Icon(Icons.person_pin_rounded, color: Colors.white),
                title: Text(
                  isSmallScreen ? 'Profile' : 'Profile Information',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  emailAddress,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: isSmallScreen ? 11 : 14,
                  ),
                ),
                trailing:
                    isSmallScreen
                        ? IconButton(
                          onPressed: saveProfile,
                          icon: const Icon(Icons.save, color: Colors.white),
                        )
                        : ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 150,
                            maxHeight: 40,
                          ),
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.save),
                            label: const Text('Save'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Theme.of(context).primaryColor,
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            onPressed: saveProfile,
                          ),
                        ),
              ),
            ),

            Expanded(
              child: ListView(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_leaveCredits.isNotEmpty)
                              LeaveCard(leaveCredits: _leaveCredits),
                            SizedBox(height: 10),
                            _formField(
                              'Employee Number',
                              employeeNumberController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Employee number required';
                                }
                                return null;
                              },
                            ),
                            _formField(
                              'First Name',
                              firstNameController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'First name required';
                                }
                                return null;
                              },
                            ),
                            _formField(
                              'Middle Name',
                              middleNameController,
                              required: false,
                            ),
                            _formField(
                              'Last Name',
                              lastNameController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Last name required';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 10),
                            TextFormField(
                              controller: birthdateController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Birthdate',
                                border: OutlineInputBorder(),
                                suffixIcon: Padding(
                                  padding: EdgeInsets.only(right: 26.0),
                                  child: Icon(Icons.calendar_today),
                                ),
                              ),
                              onTap: () async {
                                DateTime initialDate =
                                    profile?.birthdate ?? DateTime(1990);
                                DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: initialDate,
                                  firstDate: DateTime(1900),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() {
                                    birthdateController.text = DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(picked);
                                  });
                                }
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Birthdate required';
                                }
                                try {
                                  DateTime.parse(value);
                                  return null;
                                } catch (_) {
                                  return 'Invalid date format';
                                }
                              },
                            ),
                            SizedBox(height: 10),
                            if (sectionOptions.isNotEmpty)
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                value: sectionId,
                                items:
                                    sectionOptions.map((option) {
                                      return DropdownMenuItem<String>(
                                        value: option['id'],
                                        child: Text(option['name']!),
                                      );
                                    }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    sectionId = value;
                                  });
                                },
                                decoration: const InputDecoration(
                                  labelText: 'Section',
                                  border: OutlineInputBorder(),
                                ),
                                validator:
                                    (value) =>
                                        value == null || value.isEmpty
                                            ? 'Section required'
                                            : null,
                              )
                            else
                              const CircularProgressIndicator(),
                            SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value:
                                  genderController.text.isNotEmpty
                                      ? genderController.text
                                      : null,
                              items:
                                  ['Male', 'Female'].map((gender) {
                                    return DropdownMenuItem<String>(
                                      value: gender,
                                      child: Text(gender),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  genderController.text = value!;
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: 'Sex',
                                border: OutlineInputBorder(),
                              ),
                              validator:
                                  (value) =>
                                      (value == null || value.isEmpty)
                                          ? 'Sex required'
                                          : null,
                            ),
                            SizedBox(height: 10),
                            _formField(
                              'Position',
                              positionController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Position required';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 10),
                            DropdownButtonFormField<String>(
                              value:
                                  employmentStatusController.text.isNotEmpty
                                      ? employmentStatusController.text
                                      : null,
                              items:
                                  [
                                    'Permanent',
                                    'COS',
                                    'Detailed',
                                    'Resigned',
                                    'Retired',
                                    'OJT',
                                  ].map((status) {
                                    return DropdownMenuItem<String>(
                                      value: status,
                                      child: Text(status),
                                    );
                                  }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  employmentStatusController.text = value!;
                                });
                              },
                              decoration: const InputDecoration(
                                labelText: 'Employment Status',
                                border: OutlineInputBorder(),
                              ),
                              validator:
                                  (value) =>
                                      (value == null || value.isEmpty)
                                          ? 'Employment status required'
                                          : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formField(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
    bool required = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: controller,
        validator:
            validator ??
            (value) {
              if (required && (value == null || value.isEmpty)) {
                return 'Required';
              }
              return null;
            },
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
