import 'package:intl/intl.dart';
import 'package:racconnect/data/models/attendance_model.dart';

Map<String, Map<String, String>> groupAttendance(List<AttendanceModel> logs) {
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

    String? type =
        entries
            .firstWhere((e) => e.type.isNotEmpty, orElse: () => entries.first)
            .type;

    String amIn = '—', amOut = '—', pmIn = '—', pmOut = '—';

    if (times.length == 1) {
      amIn = timeFormat.format(times[0]);
    } else if (times.length <= 3) {
      amIn = timeFormat.format(times.first);
      pmOut = timeFormat.format(times.last);
    } else if (times.length == 4) {
      amIn = timeFormat.format(times[0]);
      amOut = timeFormat.format(times[1]);
      pmIn = timeFormat.format(times[2]);
      pmOut = timeFormat.format(times[3]);
    } else {
      amIn = timeFormat.format(times[0]);
      amOut = timeFormat.format(times[1]);
      pmIn = timeFormat.format(times[2]);
      pmOut = timeFormat.format(times.last);
    }

    result[date] = {
      'timeIn': amIn,
      'lunchOut': amOut,
      'lunchIn': pmIn,
      'timeOut': pmOut,
      'type': type,
    };
  });

  return result;
}
