import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:racconnect/data/models/profile_model.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';
import 'package:racconnect/logic/cubit/profile_cubit.dart';
import 'package:racconnect/presentation/widgets/mobile_button.dart';
import 'package:racconnect/utility/constants.dart';
import 'package:racconnect/utility/pocketbase_client.dart';

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

  // Account tab controllers
  late TextEditingController displayNameController;
  late TextEditingController emailController;
  late TextEditingController newPasswordController;
  late TextEditingController confirmPasswordController;
  late TextEditingController
  oldPasswordController; // New controller for old password

  final _formKey = GlobalKey<FormState>();
  final _accountFormKey = GlobalKey<FormState>();
  // Map<String, dynamic> _leaveCredits = {};
  ProfileModel? profile;
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

    // Dispose account controllers
    displayNameController.dispose();
    emailController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    oldPasswordController.dispose();
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
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthenticatedState) {
      final p = authState.user.profile;

      setState(() {
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

        // Initialize account controllers
        displayNameController = TextEditingController(
          text: authState.user.name,
        );
        emailController = TextEditingController(text: authState.user.email);
        newPasswordController = TextEditingController();
        confirmPasswordController = TextEditingController();
        oldPasswordController = TextEditingController();
      });
    }
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

    if (authState is! AuthenticatedState) return;

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirm Update'),
            content: const Text('Are you sure you want to continue?'),
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
                child: const Text('Yes, Save'),
              ),
            ],
          ),
    );
  }

  void saveAccount() {
    if (!_accountFormKey.currentState!.validate()) return;

    final authCubit = context.read<AuthCubit>();
    final authState = authCubit.state;

    if (authState is! AuthenticatedState) return;

    // Check if password fields are filled and match
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (newPassword.isNotEmpty || confirmPassword.isNotEmpty) {
      if (newPassword != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Confirm Update'),
            content: const Text(
              'Are you sure you want to update your account information?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  try {
                    final pb = PocketBaseClient.instance;

                    // Prepare update data
                    final Map<String, dynamic> updateData = {};

                    // Update display name if changed
                    final displayName = displayNameController.text.trim();
                    if (displayName != authState.user.name) {
                      updateData['name'] = displayName;
                    }

                    // Update password if provided
                    if (newPassword.isNotEmpty) {
                      final oldPassword = oldPasswordController.text;
                      if (oldPassword.isEmpty) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Current password is required to change password',
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }

                      updateData['oldPassword'] = oldPassword;
                      updateData['password'] = newPassword;
                      updateData['passwordConfirm'] = newPassword;
                    }

                    // Only proceed if there's something to update
                    if (updateData.isNotEmpty) {
                      final userId = authState.user.id!;
                      await pb
                          .collection('users')
                          .update(userId, body: updateData);

                      // Check if password was changed
                      final wasPasswordChanged = updateData.containsKey(
                        'password',
                      );

                      // Check if display name was changed
                      final wasDisplayNameChanged = updateData.containsKey(
                        'name',
                      );

                      // Refresh user data immediately if display name was changed
                      if (wasDisplayNameChanged) {
                        await authCubit.refreshCurrentUser();
                      }

                      // Clear password fields immediately
                      if (mounted) {
                        oldPasswordController.clear();
                        newPasswordController.clear();
                        confirmPasswordController.clear();
                      }

                      if (mounted) {
                        String successMessage =
                            wasPasswordChanged
                                ? 'Password changed successfully! Please log in again with your new password.'
                                : 'Account updated successfully!';

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(successMessage),
                            backgroundColor: Colors.green,
                          ),
                        );

                        // If password was changed, immediately sign out the user
                        if (wasPasswordChanged) {
                          if (mounted) {
                            context.read<AuthCubit>().signOut();
                          }
                        }
                      }
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No changes to save'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    }
                  } catch (e) {
                    // Check if this is an authentication error (likely due to password change)
                    String errorMessage = e.toString();
                    bool isAuthError =
                        errorMessage.contains('authentication') ||
                        errorMessage.contains('Authorization') ||
                        errorMessage.contains('401') ||
                        errorMessage.contains('Unauthorized') ||
                        errorMessage.contains('valid authentication token') ||
                        errorMessage.contains('auth store') ||
                        errorMessage.contains('token is outdated') ||
                        errorMessage.contains('token');

                    if (isAuthError) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Password changed successfully! Please sign in again with your new password.',
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) {
                            context.read<AuthCubit>().signOut();
                          }
                        });
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error updating account: $errorMessage',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
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
                child: const Text('Yes, Save'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isSmallScreen = width < 700;

    return BlocListener<ProfileCubit, ProfileState>(
      listener: (context, state) {
        if (state is SaveProfileSuccess) {
          final authCubit = context.read<AuthCubit>();
          final authState = authCubit.state;
          if (authState is AuthenticatedState) {
            final updatedUser = authState.user.copyWith(
              profile: () => state.profile,
            );
            authCubit.refreshUser(updatedUser);
            authCubit.refreshCurrentUser();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error), backgroundColor: Colors.red),
          );
        }
      },
      child: DefaultTabController(
        length: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Column(
            children: [
              Card(
                color: Theme.of(context).primaryColor,
                child: Column(
                  children: [
                    ListTile(
                      minTileHeight: 70,
                      leading: Icon(Icons.person, color: Colors.white),
                      title: Text(
                        'My Account',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        !isSmallScreen
                            ? 'Kindly ensure your profile information is up to date'
                            : 'Kindly keep your profile up to date',
                        style: TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                      trailing: Builder(
                        builder: (context) {
                          return MobileButton(
                            isSmallScreen: isSmallScreen,
                            onPressed: () {
                              final tabController = DefaultTabController.of(
                                context,
                              );
                              if (tabController.index == 0) {
                                saveProfile();
                              } else {
                                saveAccount();
                              }
                            },
                            icon: Icons.save,
                            label: 'Save',
                          );
                        },
                      ),
                    ),
                    TabBar(
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white70,
                      tabs: const [Tab(text: 'Profile'), Tab(text: 'Account')],
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Card(
                  child: TabBarView(
                    children: [
                      // Profile Tab
                      SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // if (_leaveCredits.isNotEmpty)
                                //   LeaveCard(leaveCredits: _leaveCredits),
                                // SizedBox(height: 10),
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
                                const SizedBox(height: 10),
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
                                const SizedBox(height: 10),
                                if (sectionOptions.isNotEmpty)
                                  DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    initialValue: sectionId,
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
                                      labelText: 'Unit',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator:
                                        (value) =>
                                            value == null || value.isEmpty
                                                ? 'Unit required'
                                                : null,
                                  )
                                else
                                  const CircularProgressIndicator(),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<String>(
                                  initialValue:
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
                                const SizedBox(height: 10),
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
                                const SizedBox(height: 10),
                                DropdownButtonFormField<String>(
                                  initialValue:
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
                      // Account Tab
                      SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _accountFormKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _formField(
                                  'Email Address',
                                  emailController,
                                  enabled: false,
                                ),
                                _formField(
                                  'Display Name',
                                  displayNameController,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Display name required';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'Change Password',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  'Note: Updating your password will require you to relogin',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _formField(
                                  'Current Password',
                                  oldPasswordController,
                                  obscureText: true,
                                  validator: (value) {
                                    // Only validate if new password is filled
                                    final newPassword =
                                        newPasswordController.text.trim();
                                    if (newPassword.isNotEmpty &&
                                        (value == null || value.isEmpty)) {
                                      return 'Current password required to change password';
                                    }
                                    return null;
                                  },
                                ),
                                _formField(
                                  'New Password',
                                  newPasswordController,
                                  validator: (value) {
                                    if (value != null &&
                                        value.isNotEmpty &&
                                        value.length < 8) {
                                      return 'Password must be at least 8 characters';
                                    }
                                    return null;
                                  },
                                  obscureText: true,
                                ),
                                Stack(
                                  children: [
                                    _formField(
                                      'Confirm Password',
                                      confirmPasswordController,
                                      validator: (value) {
                                        if (newPasswordController.text !=
                                            value) {
                                          return 'Passwords do not match';
                                        }
                                        return null;
                                      },
                                      obscureText: true,
                                    ),
                                    Positioned(
                                      right: 10,
                                      top: 30,
                                      child: ValueListenableBuilder<
                                        TextEditingValue
                                      >(
                                        valueListenable:
                                            confirmPasswordController,
                                        builder: (context, value, child) {
                                          if (value.text.isEmpty) {
                                            return const SizedBox.shrink();
                                          }
                                          final passwordsMatch =
                                              newPasswordController.text ==
                                              value.text;
                                          return Padding(
                                            padding: EdgeInsets.only(
                                              right: 20.0,
                                            ),
                                            child: Icon(
                                              passwordsMatch
                                                  ? Icons.check
                                                  : Icons.error,
                                              color:
                                                  passwordsMatch
                                                      ? Colors.green
                                                      : Colors.red,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formField(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
    bool required = true,
    bool obscureText = false,
    bool enabled = true,
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
        obscureText: obscureText,
        enabled: enabled,
      ),
    );
  }
}
