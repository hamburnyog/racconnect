import 'package:intl/intl.dart';
import 'package:racconnect/data/models/attendance_model.dart';

/// Centralized rules for grouping raw attendance logs into DTR slots.
/// 
/// Current Strategy: "First/Last Anchoring"
/// 1. AM IN: The earliest log of the day found before 12:01 PM.
/// 2. PM OUT: The latest log of the day found after 12:00 PM (must be different from AM IN).
/// 3. AM OUT: The first log after AM IN that is <= 12:59:59 PM (must be before PM OUT).
/// 4. PM IN: The first log appearing after AM OUT (or after 12:00 PM if AM OUT missing) 
///    that is strictly before PM OUT.
class AttendanceRules {
  static Map<String, AttendanceModel?> groupDayLogs(List<AttendanceModel> dayLogs) {
    if (dayLogs.isEmpty) {
      return {'amIn': null, 'amOut': null, 'pmIn': null, 'pmOut': null};
    }

    // Sort logs by time ascending
    final sortedLogs = List<AttendanceModel>.from(dayLogs);
    sortedLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    AttendanceModel? amIn;
    AttendanceModel? amOut;
    AttendanceModel? pmIn;
    AttendanceModel? pmOut;

    // 1. AM IN: First log of the day before 12:01 PM
    for (var log in sortedLogs) {
      if (log.timestamp.hour < 12 || (log.timestamp.hour == 12 && log.timestamp.minute == 0)) {
        amIn = log;
        break;
      }
    }

    // 2. PM OUT: Last log of the day after 12:00 PM (and not the same as AM IN)
    for (var log in sortedLogs.reversed) {
      if (log.timestamp.hour >= 12 && log != amIn) {
        pmOut = log;
        break;
      }
    }

    // 3. AM OUT: First log after AM IN and before 1:00 PM (and not PM OUT)
    if (amIn != null) {
      for (var log in sortedLogs) {
        if (log != amIn && log != pmOut && log.timestamp.isAfter(amIn.timestamp) && log.timestamp.hour < 13) {
          amOut = log;
          break;
        }
      }
    } else {
      // If AM IN is missing, AM OUT is the first log of the day IF it's before 1:00 PM and not the only log
      final first = sortedLogs.first;
      if (first.timestamp.hour < 13 && first != pmOut) {
        amOut = first;
      }
    }

    // 4. PM IN: First log after morning session and before PM OUT
    final pmInReferenceTime = amOut?.timestamp ?? amIn?.timestamp ?? DateTime(
      dayLogs.first.timestamp.year,
      dayLogs.first.timestamp.month,
      dayLogs.first.timestamp.day,
      12,
    );

    for (var log in sortedLogs) {
      if (log != amIn && log != amOut && log != pmOut && log.timestamp.isAfter(pmInReferenceTime)) {
        pmIn = log;
        break;
      }
    }

    return {
      'amIn': amIn,
      'amOut': amOut,
      'pmIn': pmIn,
      'pmOut': pmOut,
    };
  }

  static String formatTime(AttendanceModel? log) {
    if (log == null) return '—';
    return DateFormat('h:mm a').format(log.timestamp);
  }
}
