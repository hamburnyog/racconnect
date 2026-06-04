import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/attendance_model.dart';
import 'package:racconnect/utility/attendance_helpers.dart';

class RawLogsView extends StatelessWidget {
  final List<AttendanceModel> logs;
  final bool isLoading;
  final bool showEmployeeNumber;
  final bool showAccomplishment;
  final bool isSmallScreen;
  final Function(AttendanceModel)? onLogTap;

  const RawLogsView({
    super.key,
    required this.logs,
    this.isLoading = false,
    this.showEmployeeNumber = false,
    this.showAccomplishment = true,
    this.isSmallScreen = false,
    this.onLogTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (logs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No raw logs found for the selected period.',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    // Ensure logs are sorted by timestamp
    final sortedLogs = List<AttendanceModel>.from(logs);
    sortedLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return ListView.builder(
      itemCount: sortedLogs.length,
      shrinkWrap: isSmallScreen,
      physics: isSmallScreen ? const NeverScrollableScrollPhysics() : null,
      itemBuilder: (context, index) {
        final log = sortedLogs[index];
        final dateTimeStr = DateFormat('MMMM d, yyyy h:mm a').format(log.timestamp);
        final accomplishment = log.remarks.isNotEmpty ? log.remarks : 'No accomplishment';
        final isBio = log.type.toLowerCase().contains('biometrics');

        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
          color: Colors.grey[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          child: InkWell(
            onTap: onLogTap != null ? () => onLogTap!(log) : null,
            borderRadius: BorderRadius.circular(4),
            child: ListTile(
              dense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              leading: Icon(
                isBio ? Icons.fingerprint : Icons.home,
                size: 20,
                color: isBio ? Colors.teal : Colors.purple,
              ),
              title: Text(
                '${showEmployeeNumber ? '[${log.employeeNumber}] ' : ''}$dateTimeStr${showAccomplishment ? ' - \'$accomplishment\'' : ''}',
                style: const TextStyle(
                  fontSize: 13,
                ),
              ),
              trailing: SizedBox(
                width: 60,
                child: buildBadge(log.type, smallScreen: true),
              ),
            ),
          ),
        );
      },
    );
  }
}
