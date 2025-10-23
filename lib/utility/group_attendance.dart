import 'package:intl/intl.dart';
import 'package:racconnect/data/models/attendance_model.dart';
import 'package:racconnect/data/models/suspension_model.dart';

Map<String, Map<String, String>> groupAttendance(
  List<AttendanceModel> logs,
  Map<DateTime, SuspensionModel> suspensionMap,
) {
  final Map<String, List<AttendanceModel>> groupedLogs = {};

  for (var log in logs) {
    final dateKey = DateFormat('yyyy-MM-dd').format(log.timestamp);
    groupedLogs.putIfAbsent(dateKey, () => []).add(log);
  }

  final Map<String, Map<String, String>> result = {};
  final timeFormat = DateFormat('hh:mm a');

  groupedLogs.forEach((date, entries) {
    entries.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final times = entries.map((e) => e.timestamp).toList();
    final remarks = entries.map((e) => e.remarks).toList();

    // Determine the type for the day, considering presence of both biometrics and WFH
    String? type;
    final hasBiometrics = entries.any((e) => e.type.toLowerCase() == 'biometrics');
    final hasWFH = entries.any((e) => e.type.toLowerCase().contains('wfh'));
    
    if (hasBiometrics && hasWFH) {
      // If both biometrics and WFH logs exist, set type to indicate both
      type = 'Biometrics+WFH';
    } else if (hasBiometrics) {
      // If only biometrics logs exist
      type = 'Biometrics';
    } else if (hasWFH) {
      // If only WFH logs exist
      type = 'WFH';
    } else {
      // Otherwise, use the first non-empty type or first entry's type
      type = entries
          .firstWhere((e) => e.type.isNotEmpty, orElse: () => entries.first)
          .type;
    }

    String amIn = '—', amOut = '—', pmIn = '—', pmOut = '—';
    String timeInRemarks = 'No targets specified';
    String timeOutRemarks = 'No accomplishments specified';

    // Check if the day should be considered WFH for calculations (only if NO biometric logs)
    final isWFH = hasWFH && !hasBiometrics;

    final currentDate = DateTime.parse(date);
    final isSuspension = suspensionMap.containsKey(currentDate);
    final suspensionModel = suspensionMap[currentDate];

    if (isSuspension) {
      if (suspensionModel!.isHalfday) {
        if (times.isNotEmpty) {
          amIn = timeFormat.format(times.first);
          amOut = timeFormat.format(suspensionModel.datetime);
          pmIn = '—';
          pmOut = '—';
          timeInRemarks = remarks.first;
          timeOutRemarks = 'Suspension: ${suspensionModel.name}';
        } else {
          amIn = '—';
          amOut = '—';
          pmIn = '—';
          pmOut = '—';
          timeInRemarks = 'Absent';
          timeOutRemarks = 'Absent';
        }
      } else {
        amIn = '—';
        amOut = '—';
        pmIn = '—';
        pmOut = '—';
        timeInRemarks = 'Absent';
        timeOutRemarks = 'Absent';
      }
    } else if (times.length == 1) {
      amIn = timeFormat.format(times[0]);
      timeInRemarks = remarks[0];
      if (isWFH) {
        final amInDateTime = times[0];
        if (amInDateTime.hour >= 12) {
          amOut = '—';
          pmIn = '—';
        } else {
          amOut = '12:00 PM';
          pmIn = '01:00 PM';
        }
      }
    } else if (times.length <= 3) {
      amIn = timeFormat.format(times.first);
      pmOut = timeFormat.format(times.last);
      timeInRemarks = remarks.first;
      timeOutRemarks = remarks.last;
      if (isWFH) {
        final amInDateTime = times.first;
        if (amInDateTime.hour >= 12) {
          amOut = '—';
          pmIn = '—';
        } else {
          amOut = '12:00 PM';
          pmIn = '01:00 PM';
        }
      }
    } else if (times.length == 4) {
      amIn = timeFormat.format(times[0]);
      pmOut = timeFormat.format(times[3]);
      timeInRemarks = remarks[0];
      timeOutRemarks = remarks[3];
      if (isWFH) {
        final amInDateTime = times[0];
        if (amInDateTime.hour >= 12) {
          amOut = '—';
          pmIn = '—';
        } else {
          amOut = '12:00 PM';
          pmIn = '01:00 PM';
        }
      } else {
        amOut = timeFormat.format(times[1]);
        pmIn = timeFormat.format(times[2]);
      }
    } else {
      amIn = timeFormat.format(times[0]);
      pmOut = timeFormat.format(times.last);
      timeInRemarks = remarks[0];
      timeOutRemarks = remarks.last;
      if (isWFH) {
        final amInDateTime = times[0];
        if (amInDateTime.hour >= 12) {
          amOut = '—';
          pmIn = '—';
        } else {
          amOut = '12:00 PM';
          pmIn = '01:00 PM';
        }
      } else {
        amOut = timeFormat.format(times[1]);
        pmIn = timeFormat.format(times[2]);
      }
    }

    result[date] = {
      'timeIn': amIn,
      'lunchOut': amOut,
      'lunchIn': pmIn,
      'timeOut': pmOut,
      'type': type,
      'timeInRemarks': timeInRemarks,
      'timeOutRemarks': timeOutRemarks,
    };
  });

  return result;
}
