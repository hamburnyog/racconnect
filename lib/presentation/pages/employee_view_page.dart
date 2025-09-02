import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/accomplishment_model.dart';
import 'package:racconnect/data/models/attendance_model.dart';
import 'package:racconnect/data/models/user_model.dart';
import 'package:racconnect/data/repositories/accomplishment_repository.dart';
import 'package:racconnect/data/repositories/attendance_repository.dart';
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
  late Future<Map<String, dynamic>> _dataFuture;
  bool _hasAttendanceToday = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _dataFuture = _fetchData();
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
    super.dispose();
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
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Employee Info
                SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
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
                          trailing: Icon(
                            _getGenderIcon(profile.gender),
                            color: Colors.white,
                            size: 34,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                          snapshot.data!['attendance'] as List<AttendanceModel>;
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

  IconData _getGenderIcon(String gender) {
    if (gender.toLowerCase() == 'female') {
      return Icons.female;
    } else if (gender.toLowerCase() == 'male') {
      return Icons.male;
    } else {
      return Icons.transgender;
    }
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
