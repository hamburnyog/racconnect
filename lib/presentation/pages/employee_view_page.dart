import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/accomplishment_model.dart';
import 'package:racconnect/data/models/attendance_model.dart';
import 'package:racconnect/data/models/user_model.dart';
import 'package:racconnect/data/repositories/accomplishment_repository.dart';
import 'package:racconnect/data/repositories/attendance_repository.dart';
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
    final width = MediaQuery.of(context).size.width;
    final bool isSmallScreen = width < 700;
    final profile = widget.user.profile;

    if (profile == null) {
      return const Center(child: Text('This user does not have a profile.'));
    }

    final avatarUrl = getPocketBaseFileUrl(widget.user.avatar, widget.user.id);
    final middleInitial =
        profile.middleName != null && profile.middleName!.isNotEmpty
            ? ' ${profile.middleName![0]}.'
            : '';

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Basic Information'),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_hasAttendanceToday) ...[
                      Icon(
                        Icons.broadcast_on_personal_outlined,
                        color: Colors.green,
                      ),
                    ],
                    SizedBox(width: 8),
                    Text('Current WFH Details'),
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
                            isSmallScreen
                                ? 'Employee Details'
                                : 'Employee Profile Information',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            'Details for ${profile.firstName}$middleInitial ${profile.lastName}',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoField(
                                'Employee Number',
                                profile.employeeNumber ?? 'N/A',
                              ),
                              _buildInfoField('First Name', profile.firstName),
                              _buildInfoField(
                                'Middle Name',
                                profile.middleName ?? 'N/A',
                              ),
                              _buildInfoField('Last Name', profile.lastName),
                              _buildInfoField(
                                'Birthdate',
                                DateFormat(
                                  'yyyy-MM-dd',
                                ).format(profile.birthdate),
                              ),
                              _buildInfoField('Gender', profile.gender),
                              _buildInfoField('Position', profile.position),
                              _buildInfoField(
                                'Employment Status',
                                profile.employmentStatus,
                              ),
                              _buildInfoField(
                                'Unit',
                                profile.sectionName ?? 'N/A',
                              ),
                            ],
                          ),
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
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
                      final attendance =
                          snapshot.data!['attendance'] as List<AttendanceModel>;
                      final accomplishment =
                          snapshot.data!['accomplishment']
                              as AccomplishmentModel?;

                      return SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Attendance',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            if (attendance.isEmpty)
                              Center(child: Text('No attendance for today.'))
                            else
                              ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: attendance.length,
                                itemBuilder: (context, index) {
                                  final log = attendance[index];
                                  return ListTile(
                                    leading: Icon(
                                      log.type == 'Time In'
                                          ? Icons.login
                                          : Icons.logout,
                                    ),
                                    title: Text(log.type),
                                    subtitle: Text(
                                      DateFormat(
                                        'hh:mm:ss a',
                                      ).format(log.timestamp),
                                    ),
                                  );
                                },
                              ),
                            SizedBox(height: 20),
                            Text(
                              'Accomplishments',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            if (accomplishment == null)
                              Center(
                                child: Text('No accomplishments for today.'),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Target:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(accomplishment.target),
                                    SizedBox(height: 20),
                                    Text(
                                      'Accomplishment:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(accomplishment.accomplishment),
                                  ],
                                ),
                              ),
                          ],
                        ),
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
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Divider(),
        ],
      ),
    );
  }
}
