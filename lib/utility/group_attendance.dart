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

    String? type =
        entries
            .firstWhere((e) => e.type.isNotEmpty, orElse: () => entries.first)
            .type;

    String amIn = '—', amOut = '—', pmIn = '—', pmOut = '—';
    String timeInRemarks = 'No targets specified';
    String timeOutRemarks = 'No accomplishments specified';

    final isWFH = type.toLowerCase().contains('wfh');

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
      'hasAccomplishments': entries.any((e) => e.accomplishmentId != null).toString(),
    };
  });

  return result;
}
