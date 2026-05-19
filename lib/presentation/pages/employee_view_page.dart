import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/accomplishment_model.dart';
import 'package:racconnect/data/models/attendance_model.dart';
import 'package:racconnect/data/models/profile_model.dart';
import 'package:racconnect/data/models/section_model.dart';
import 'package:racconnect/data/models/user_model.dart';
import 'package:racconnect/data/repositories/accomplishment_repository.dart';
import 'package:racconnect/data/repositories/attendance_repository.dart';
import 'package:racconnect/data/repositories/profile_repository.dart';
import 'package:racconnect/data/repositories/section_repository.dart';
import 'package:racconnect/presentation/widgets/wfh_info_display.dart';
import 'package:racconnect/utility/constants.dart';

String? getPocketBaseFileUrl(String? filename, String? recordId) {
  if (filename == null ||
      filename.isEmpty ||
      recordId == null ||
      recordId.isEmpty) {
    return null;
  }
  return '$serverUrl/api/files/_pb_users_auth_/$recordId/$filename';
}

class EmployeeViewPage extends StatefulWidget {
  final UserModel user;
  const EmployeeViewPage({required this.user, super.key});

  @override
  State<EmployeeViewPage> createState() => _EmployeeViewPageState();
}

class _EmployeeViewPageState extends State<EmployeeViewPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _attendanceRepository = AttendanceRepository();
  final _accomplishmentRepository = AccomplishmentRepository();
  final _profileRepository = ProfileRepository();
  final _sectionRepository = SectionRepository();

  late Future<Map<String, dynamic>> _dataFuture;
  bool _hasAttendanceToday = false;

  bool _isEditing = false;
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _firstNameController;
  late TextEditingController _middleNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _employeeNumberController;
  late TextEditingController _bioIdController;
  late TextEditingController _positionController;

  DateTime? _selectedBirthdate;
  String? _selectedGender;
  String? _selectedEmploymentStatus;
  String? _selectedSectionId;

  List<SectionModel> _sections = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _dataFuture = _fetchData();
    _initializeControllers();
    _fetchSections();
  }

  void _initializeControllers() {
    final profile = widget.user.profile;
    _firstNameController = TextEditingController(text: profile?.firstName);
    _middleNameController = TextEditingController(text: profile?.middleName);
    _lastNameController = TextEditingController(text: profile?.lastName);
    _employeeNumberController = TextEditingController(
      text: profile?.employeeNumber,
    );
    _bioIdController = TextEditingController(text: profile?.bioId);
    _positionController = TextEditingController(text: profile?.position);
    _selectedBirthdate = profile?.birthdate;
    _selectedGender = profile?.gender;
    _selectedEmploymentStatus = profile?.employmentStatus;
    _selectedSectionId = profile?.section;
  }

  Future<void> _fetchSections() async {
    try {
      final sections = await _sectionRepository.getAllSections(null);
      if (mounted) {
        setState(() {
          _sections = sections;
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<Map<String, dynamic>> _fetchData() async {
    final employeeNumber = widget.user.profile?.employeeNumber;
    if (employeeNumber == null) {
      return {'attendance': [], 'accomplishment': null};
    }

    final attendance = await _attendanceRepository.getEmployeeAttendanceToday(
      employeeNumber,
    );
    final accomplishment = await _accomplishmentRepository
        .getAccomplishmentByDate(DateTime.now(), employeeNumber);

    if (mounted) {
      setState(() {
        _hasAttendanceToday = attendance.isNotEmpty;
      });
    }

    return {'attendance': attendance, 'accomplishment': accomplishment};
  }

  @override
  void dispose() {
    _tabController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _employeeNumberController.dispose();
    _bioIdController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedProfile = ProfileModel(
        id: widget.user.profile?.id,
        firstName: _firstNameController.text.trim(),
        middleName: _middleNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        employeeNumber: _employeeNumberController.text.trim(),
        bioId: _bioIdController.text.trim(),
        position: _positionController.text.trim(),
        birthdate: _selectedBirthdate ?? DateTime.now(),
        gender: _selectedGender ?? 'Male',
        employmentStatus: _selectedEmploymentStatus ?? 'Permanent',
        section: _selectedSectionId,
      );

      await _profileRepository.saveProfile(
        id: widget.user.profile?.id,
        profile: updatedProfile,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isEditing = false;
        });
        // We might want to refresh the parent page or update the local user object
        // For now, just close the edit mode.
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.user.profile;

    if (profile == null) {
      return const Center(child: Text('This user does not have a profile.'));
    }

    final avatarUrl = getPocketBaseFileUrl(widget.user.avatar, widget.user.id);

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              const Tab(text: 'Basic Information'),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_hasAttendanceToday) ...[
                      const Icon(
                        Icons.broadcast_on_personal_outlined,
                        color: Colors.green,
                      ),
                    ],
                    const SizedBox(width: 8),
                    const Text('WFH Information'),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Employee Info
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Card(
                          color: Theme.of(context).primaryColor,
                          child: ListTile(
                            minTileHeight: 70,
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundColor: Theme.of(context).primaryColor,
                              backgroundImage:
                                  avatarUrl != null
                                      ? NetworkImage(avatarUrl)
                                      : null,
                              child:
                                  avatarUrl == null
                                      ? const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                      )
                                      : null,
                            ),
                            title: Text(
                              '${profile.lastName}, ${profile.firstName} ${profile.middleName}'
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Text(
                              'Employee Number: ${profile.employeeNumber ?? 'N/A'}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                _isEditing ? Icons.close : Icons.edit,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  if (_isEditing) {
                                    _initializeControllers();
                                  }
                                  _isEditing = !_isEditing;
                                });
                              },
                            ),
                          ),
                        ),
                        if (_isEditing) ...[
                          const SizedBox(height: 20),
                          _buildTextField(_firstNameController, 'First Name'),
                          _buildTextField(_middleNameController, 'Middle Name'),
                          _buildTextField(_lastNameController, 'Last Name'),
                          _buildTextField(
                            _employeeNumberController,
                            'Employee Number',
                          ),
                          _buildTextField(_bioIdController, 'Bio ID'),
                          _buildTextField(_positionController, 'Position'),
                          _buildDatePicker('Birthdate'),
                          _buildDropdownField(
                            'Gender',
                            ['Male', 'Female'],
                            _selectedGender,
                            (val) => setState(() => _selectedGender = val),
                          ),
                          _buildDropdownField(
                            'Employment Status',
                            [
                              'Permanent',
                              'Casual',
                              'Contractual',
                              'Job Order',
                              'COS',
                              'Detailed',
                              'Resigned',
                              'Retired',
                              'OJT',
                            ],
                            _selectedEmploymentStatus,
                            (val) =>
                                setState(() => _selectedEmploymentStatus = val),
                          ),
                          _buildSectionDropdown(),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _isSaving ? null : _saveProfile,
                              child:
                                  _isSaving
                                      ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                      : const Text('Save Changes'),
                            ),
                          ),
                        ] else ...[
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoField('Bio ID', profile.bioId ?? 'N/A'),
                                _buildInfoField(
                                  'Employment Status',
                                  profile.employmentStatus.toUpperCase(),
                                ),
                                _buildInfoField(
                                  'Birthdate',
                                  '${DateFormat('yyyy-MM-dd').format(profile.birthdate)} (${_calculateAge(profile.birthdate)})',
                                ),
                                _buildInfoField(
                                  'Position',
                                  profile.position.toUpperCase(),
                                ),
                                _buildInfoField(
                                  'Unit',
                                  (profile.sectionName ?? 'N/A').toUpperCase(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Tab 2: Attendance & Accomplishments
                FutureBuilder<Map<String, dynamic>>(
                  future: _dataFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
                      final attendance =
                          snapshot.data!['attendance']
                              as List<AttendanceModel>;
                      final accomplishment =
                          snapshot.data!['accomplishment']
                              as AccomplishmentModel?;

                      return WfhInfoDisplay(
                        attendance: attendance,
                        accomplishment: accomplishment,
                        date: DateTime.now(),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            if (label == 'Middle Name') return null;
            return 'Please enter $label';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDatePicker(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: _selectedBirthdate ?? DateTime(1990),
            firstDate: DateTime(1950),
            lastDate: DateTime.now(),
          );
          if (date != null) {
            setState(() {
              _selectedBirthdate = date;
            });
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          child: Text(
            _selectedBirthdate != null
                ? DateFormat('yyyy-MM-dd').format(_selectedBirthdate!)
                : 'Select Birthdate',
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    List<String> options,
    String? selectedValue,
    Function(String?) onChanged,
  ) {
    // Ensure the selected value is in the options to prevent assertion errors
    final effectiveValue = options.contains(selectedValue) ? selectedValue : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: effectiveValue,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        items:
            options.map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Please select $label' : null,
      ),
    );
  }

  Widget _buildSectionDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: _selectedSectionId,
        decoration: const InputDecoration(
          labelText: 'Unit/Section',
          border: OutlineInputBorder(),
        ),
        items:
            _sections.map((SectionModel section) {
              return DropdownMenuItem<String>(
                value: section.id,
                child: Text('${section.code} - ${section.name}'),
              );
            }).toList(),
        onChanged: (value) => setState(() => _selectedSectionId = value),
        validator: (value) => value == null ? 'Please select Section' : null,
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.purple)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  String _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return '$age';
  }
}
