import 'dart:io';
import 'package:path_provider/path_provider.dart';

String getMonthName(int month) {
  const List<String> monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return monthNames[month - 1];
}

int getDaysInMonth(int year, int month) {
  if (month < 1 || month > 12) {
    throw ArgumentError('Month must be between 1 and 12');
  }
  var firstDayOfMonth = DateTime(year, month, 1);
  var firstDayOfNextMonth = DateTime(year, month + 1, 1);
  return firstDayOfNextMonth.difference(firstDayOfMonth).inDays;
}

String getDayName(int weekday) {
  const List<String> dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  return dayNames[weekday - 1];
}

List<String> getDayNamesInMonth(int year, int month) {
  List<String> dayNames = [];
  int daysInMonth = getDaysInMonth(year, month);
  for (int day = 1; day <= daysInMonth; day++) {
    DateTime date = DateTime(year, month, day);
    dayNames.add(getDayName(date.weekday));
  }
  return dayNames;
}

Future<String?> getPlatformDownloadPath() async {
  try {
    if (Platform.isAndroid) {
      Directory directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory =
            await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
      }
      return directory.path;
    }

    if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }

    if (Platform.isMacOS || Platform.isLinux) {
      final home = Platform.environment['HOME'];
      return home != null ? '$home/Downloads' : null;
    }

    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      return userProfile != null ? '$userProfile\\Downloads' : null;
    }
  } catch (e) {
    rethrow;
  }

  return null;
}

extension DateTimeCopyWith on DateTime {
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
  }) {
    return DateTime(
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      millisecond ?? this.millisecond,
      microsecond ?? this.microsecond,
    );
  }
}