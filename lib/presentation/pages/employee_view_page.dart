import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/user_model.dart';
import 'package:racconnect/utility/constants.dart';

String? getPocketBaseFileUrl(String? filename, String? recordId) {
  if (filename == null || filename.isEmpty || recordId == null || recordId.isEmpty) {
    return null;
  }
  return '$serverUrl/api/files/_pb_users_auth_/$recordId/$filename';
}

class EmployeeViewPage extends StatelessWidget {
  final UserModel user;
  const EmployeeViewPage({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isSmallScreen = width < 700;
    final profile = user.profile;

    if (profile == null) {
      return const Center(
        child: Text('This user does not have a profile.'),
      );
    }

    final avatarUrl = getPocketBaseFileUrl(user.avatar, user.id);
    final middleInitial = profile.middleName != null && profile.middleName!.isNotEmpty
        ? ' ${profile.middleName![0]}.'
        : '';

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SingleChildScrollView(
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
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
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
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // if (profile.sl != null || profile.vl != null || profile.spl != null || profile.cto != null)
                    //   LeaveCard(leaveCredits: {
                    //     'SL': profile.sl ?? 0,
                    //     'VL': profile.vl ?? 0,
                    //     'SPL': profile.spl ?? 0,
                    //     'CTO': profile.cto ?? 0,
                    //   }),
                    // SizedBox(height: 10),
                    _buildInfoField(
                      'Employee Number',
                      profile.employeeNumber ?? 'N/A',
                    ),
                    _buildInfoField('First Name', profile.firstName),
                    _buildInfoField('Middle Name', profile.middleName ?? 'N/A'),
                    _buildInfoField('Last Name', profile.lastName),
                    _buildInfoField(
                      'Birthdate',
                      DateFormat('yyyy-MM-dd').format(profile.birthdate),
                    ),
                    _buildInfoField('Gender', profile.gender),
                    _buildInfoField('Position', profile.position),
                    _buildInfoField(
                      'Employment Status',
                      profile.employmentStatus,
                    ),
                    _buildInfoField('Unit', profile.sectionName ?? 'N/A'),
                  ],
                ),
              ),
            ),
          ],
        ),
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
