import 'dart:io';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:racconnect/data/models/attendance_model.dart';
import 'package:racconnect/data/models/profile_model.dart';
import 'package:racconnect/data/models/suspension_model.dart';

import 'constants.dart';
import 'excel_utils.dart';
import 'excel_helpers.dart';

Future<String?> generateExcel(
  DateTime selectedDate,
  ProfileModel profile,
  List<AttendanceModel> monthlyAttendance,
  Map<DateTime, String> holidayMap,
  Map<DateTime, SuspensionModel> suspensionMap,
  Map<DateTime, String> leaveMap,
  Map<DateTime, String> travelMap, {
  DateTime? startDate,
  DateTime? endDate,
}) async {
  bool fileExists = false;

  var excel = Excel.createExcel();
  excel.rename('Sheet1', 'DTR TEMPLATE');
  Sheet sheet = excel['DTR TEMPLATE'];

  int currentMonth = selectedDate.month;
  int currentYear = selectedDate.year;

  String monthName = getMonthName(currentMonth);

  String firstName = profile.firstName;
  String middleName = profile.middleName ?? '';
  String lastName = profile.lastName;

  String middleInitial = middleName.isNotEmpty ? '${middleName[0]}.' : '';
  String fullName = '$firstName $middleInitial $lastName'.trim().toUpperCase();

  String position = profile.position;
  String supervisor;
  String supervisorDesignation;

  if (profile.sectionCode == 'OIC') {
    supervisor = 'Immediate Supervisor';
    supervisorDesignation = '';
  } else {
    supervisor =
        profile.section ==
                'y78rsxd4495cz25' // Hardcode for now
            ? 'HON. ROWENA M. MACALINTAL, ASEC'
            : 'JOHN S. CALIDGUID, RSW, MPA';
    supervisorDesignation =
        profile.section ==
                'y78rsxd4495cz25' // Hardcode for now
            ? 'Deputy Director for Operations and Services'
            : 'Officer-in-charge, SWO IV';
  }

  // Headers
  String monthYearText =
      'FOR THE MONTH OF ${monthName.toUpperCase()} ${currentYear.toString()}';

  // Build header section
  buildHeaderSection(sheet, fullName, monthYearText);

  // Days - always show all days of the month
  var monthDayNames = getDayNamesInMonth(currentYear, currentMonth);
  var lastDay = DateTime(currentYear, currentMonth + 1, 0).day;
  var startingRowNumber = 13;

  // Determine which days should have data (if date range is specified)
  Set<DateTime> daysWithData = {};
  if (startDate != null && endDate != null) {
    // Only include days within the specified range
    for (int day = startDate.day; day <= endDate.day; day++) {
      daysWithData.add(DateTime(startDate.year, startDate.month, day));
    }
  } else {
    // Include all days of the month
    for (int day = 1; day <= lastDay; day++) {
      daysWithData.add(DateTime(currentYear, currentMonth, day));
    }
  }

  Map<String, dynamic> cellList = {};
  Map<String, dynamic> cellList2 = {};

  int totalLateUndertimeHours = 0;
  int totalLateUndertimeMinutes = 0;

  // Process all days of the month
  for (int day = 1; day <= lastDay; day++) {
    var currrentRowNumber = startingRowNumber.toString();
    final currentDate = DateTime(currentYear, currentMonth, day);
    final isWeekend =
        monthDayNames[day - 1] == 'Saturday' ||
        monthDayNames[day - 1] == 'Sunday';

    // Check if this day should have data
    final shouldHaveData = daysWithData.contains(currentDate);

    if (shouldHaveData) {
      // Process this day with actual data
      final isHoliday = holidayMap.containsKey(currentDate);
      final holidayName = holidayMap[currentDate];

      // Check for leaves
      final isLeave = leaveMap.containsKey(currentDate);
      final leaveName = leaveMap[currentDate];

      // Check for travel orders
      final isTravel = travelMap.containsKey(currentDate);
      final travelName = travelMap[currentDate];

      // If it's a leave or travel order, treat it like a holiday but with appropriate prefix
      final effectiveHoliday = isHoliday || isLeave || isTravel;
      final effectiveHolidayName =
          isHoliday
              ? holidayName
              : (isLeave
                  ? "LEAVE - $leaveName"
                  : (isTravel ? "TRAVEL - $travelName" : null));

      final dayLogs =
          monthlyAttendance.where((log) {
            return log.timestamp.year == currentDate.year &&
                log.timestamp.month == currentDate.month &&
                log.timestamp.day == currentDate.day;
          }).toList();

      final logTimes = extractLogTimes(dayLogs);
      bool isWFH = dayLogs.any((log) => log.type.toLowerCase() == 'wfh');
      String amIn = logTimes['amIn'] ?? '';
      String pmOut = logTimes['pmOut'] ?? '';

      final dateFormat = DateFormat('h:mm a');

      String amOut = logTimes['amOut'] ?? '';
      String pmIn = logTimes['pmIn'] ?? '';

      final isSuspension = suspensionMap.containsKey(currentDate);
      final suspensionModel = suspensionMap[currentDate];

      if (isSuspension) {
        if (suspensionModel!.isHalfday) {
          if (amIn.isNotEmpty) {
            amOut = dateFormat.format(suspensionModel.datetime);
            pmIn = '';
            pmOut = '';
          } else {
            amIn = '';
            amOut = '';
            pmIn = '';
            pmOut = '';
          }
        } else {
          amIn = '';
          amOut = '';
          pmIn = '';
          pmOut = '';
        }
      } else if (isWFH) {
        final amInDateTime =
            amIn.isNotEmpty
                ? dateFormat
                    .parse(amIn)
                    .copyWith(
                      year: currentDate.year,
                      month: currentDate.month,
                      day: currentDate.day,
                    )
                : null;

        if (amInDateTime != null && amInDateTime.hour < 12) {
          amOut = '12:00 PM';
          pmIn = '1:00 PM';
        }
      }

      if (isWeekend) {
        cellList['A$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('A$currrentRowNumber'),
        );
        cellList['A$currrentRowNumber'].value = IntCellValue(day);
        cellList['A$currrentRowNumber'].cellStyle = borderedCellStyle;

        sheet.merge(
          CellIndex.indexByString('B$currrentRowNumber'),
          CellIndex.indexByString('E$currrentRowNumber'),
          customValue: TextCellValue(monthDayNames[day - 1].toUpperCase()),
        );

        for (var col in ['B', 'C', 'D', 'E', 'F', 'G']) {
          cellList['$col$currrentRowNumber'] = sheet.cell(
            CellIndex.indexByString('$col$currrentRowNumber'),
          );
          cellList['$col$currrentRowNumber'].cellStyle =
              ['B', 'F', 'G'].contains(col)
                  ? borderedCellStyle
                  : topBottomBorderCellStyle;
        }

        cellList2['I$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('I$currrentRowNumber'),
        );
        cellList2['I$currrentRowNumber'].value = IntCellValue(day);
        cellList2['I$currrentRowNumber'].cellStyle = borderedCellStyle;

        sheet.merge(
          CellIndex.indexByString('J$currrentRowNumber'),
          CellIndex.indexByString('M$currrentRowNumber'),
          customValue: TextCellValue(monthDayNames[day - 1].toUpperCase()),
        );

        for (var col in ['J', 'K', 'L', 'M', 'N', 'O']) {
          cellList['$col$currrentRowNumber'] = sheet.cell(
            CellIndex.indexByString('$col$currrentRowNumber'),
          );
          cellList['$col$currrentRowNumber'].cellStyle =
              ['J', 'N', 'O'].contains(col)
                  ? borderedCellStyle
                  : topBottomBorderCellStyle;
        }
      } else if (effectiveHoliday) {
        // Holiday/Leave format
        cellList['A$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('A$currrentRowNumber'),
        );
        cellList['A$currrentRowNumber'].value = IntCellValue(day);
        cellList['A$currrentRowNumber'].cellStyle = borderedCellStyle;

        sheet.merge(
          CellIndex.indexByString('B$currrentRowNumber'),
          CellIndex.indexByString('E$currrentRowNumber'),
          customValue: TextCellValue(effectiveHolidayName!.toUpperCase()),
        );

        for (var col in ['F', 'G']) {
          cellList['$col$currrentRowNumber'] = sheet.cell(
            CellIndex.indexByString('$col$currrentRowNumber'),
          );
          cellList['$col$currrentRowNumber'].value = null;
          cellList['$col$currrentRowNumber'].cellStyle = borderedCellStyle;
        }

        cellList2['I$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('I$currrentRowNumber'),
        );
        cellList2['I$currrentRowNumber'].value = IntCellValue(day);
        cellList2['I$currrentRowNumber'].cellStyle = borderedCellStyle;

        sheet.merge(
          CellIndex.indexByString('J$currrentRowNumber'),
          CellIndex.indexByString('M$currrentRowNumber'),
          customValue: TextCellValue(effectiveHolidayName.toUpperCase()),
        );

        for (var col in ['B', 'C', 'D', 'E']) {
          cellList['$col$currrentRowNumber'] ??= sheet.cell(
            CellIndex.indexByString('$col$currrentRowNumber'),
          );
          cellList['$col$currrentRowNumber'].cellStyle =
              topBottomBorderCellStyle;
        }

        for (var col in ['J', 'K', 'L', 'M']) {
          cellList['$col$currrentRowNumber'] ??= sheet.cell(
            CellIndex.indexByString('$col$currrentRowNumber'),
          );
          cellList['$col$currrentRowNumber'].cellStyle =
              topBottomBorderCellStyle;
        }

        for (var col in ['N', 'O']) {
          cellList['$col$currrentRowNumber'] = sheet.cell(
            CellIndex.indexByString('$col$currrentRowNumber'),
          );
          cellList['$col$currrentRowNumber'].value = null;
          cellList['$col$currrentRowNumber'].cellStyle = borderedCellStyle;
        }
      } else if (isSuspension) {
        // NEW SUSPENSION BLOCK
        cellList['A$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('A$currrentRowNumber'),
        );
        cellList['A$currrentRowNumber'].value = IntCellValue(day);
        cellList['A$currrentRowNumber'].cellStyle = borderedCellStyle;

        if (suspensionModel!.isHalfday && amIn.isNotEmpty) {
          // Half-day suspension with time-in
          // Display amIn and amOut (which is suspension time)
          cellList['B$currrentRowNumber'] = sheet.cell(
            CellIndex.indexByString('B$currrentRowNumber'),
          );
          cellList['B$currrentRowNumber'].value = TextCellValue(amIn);
          cellList['B$currrentRowNumber'].cellStyle = borderedCellStyle;

          cellList['C$currrentRowNumber'] = sheet.cell(
            CellIndex.indexByString('C$currrentRowNumber'),
          );
          cellList['C$currrentRowNumber'].value = TextCellValue(amOut);
          cellList['C$currrentRowNumber'].cellStyle = borderedCellStyle;

          // Merge PM cells and display suspension name
          sheet.merge(
            CellIndex.indexByString('D$currrentRowNumber'),
            CellIndex.indexByString('E$currrentRowNumber'), // Merges D and E
            customValue: TextCellValue(suspensionModel.name.toUpperCase()),
          );
          for (var col in ['D', 'E']) {
            // Apply styles to merged cells
            cellList['$col$currrentRowNumber'] ??= sheet.cell(
              CellIndex.indexByString('$col$currrentRowNumber'),
            );
            cellList['$col$currrentRowNumber'].cellStyle =
                topBottomBorderCellStyle;
          }

          // Set late/undertime to null for half-day suspension
          for (var col in ['F', 'G']) {
            cellList['$col$currrentRowNumber'] = sheet.cell(
              CellIndex.indexByString('$col$currrentRowNumber'),
            );
            cellList['$col$currrentRowNumber'].value = null;
            cellList['$col$currrentRowNumber'].cellStyle = borderedCellStyle;
          }
        } else {
          // Full-day suspension or half-day with no time-in (treated as full absence)
          sheet.merge(
            CellIndex.indexByString('B$currrentRowNumber'),
            CellIndex.indexByString('E$currrentRowNumber'), // Merges B, C, D, E
            customValue: TextCellValue(suspensionModel.name.toUpperCase()),
          );
          for (var col in ['B', 'C', 'D', 'E']) {
            // Apply styles to merged cells
            cellList['$col$currrentRowNumber'] ??= sheet.cell(
              CellIndex.indexByString('$col$currrentRowNumber'),
            );
            cellList['$col$currrentRowNumber'].cellStyle =
                topBottomBorderCellStyle;
          }

          // Set late/undertime to null for full-day suspension
          for (var col in ['F', 'G']) {
            cellList['$col$currrentRowNumber'] = sheet.cell(
              CellIndex.indexByString('$col$currrentRowNumber'),
            );
            cellList['$col$currrentRowNumber'].value = null;
            cellList['$col$currrentRowNumber'].cellStyle = borderedCellStyle;
          }
        }

        // Mirrored columns I to O (similar to holiday logic)
        cellList2['I$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('I$currrentRowNumber'),
        );
        cellList2['I$currrentRowNumber'].value = IntCellValue(day);
        cellList2['I$currrentRowNumber'].cellStyle = borderedCellStyle;

        if (suspensionModel.isHalfday && amIn.isNotEmpty) {
          cellList['J$currrentRowNumber'] = sheet.cell(
            CellIndex.indexByString('J$currrentRowNumber'),
          );
          cellList['J$currrentRowNumber'].value = TextCellValue(amIn);
          cellList['J$currrentRowNumber'].cellStyle = borderedCellStyle;

          cellList['K$currrentRowNumber'] = sheet.cell(
            CellIndex.indexByString('K$currrentRowNumber'),
          );
          cellList['K$currrentRowNumber'].value = TextCellValue(amOut);
          cellList['K$currrentRowNumber'].cellStyle = borderedCellStyle;

          sheet.merge(
            CellIndex.indexByString('L$currrentRowNumber'),
            CellIndex.indexByString('M$currrentRowNumber'),
            customValue: TextCellValue(suspensionModel.name.toUpperCase()),
          );
          for (var col in ['L', 'M']) {
            cellList['$col$currrentRowNumber'] ??= sheet.cell(
              CellIndex.indexByString('$col$currrentRowNumber'),
            );
            cellList['$col$currrentRowNumber'].cellStyle =
                topBottomBorderCellStyle;
          }

          for (var col in ['N', 'O']) {
            cellList['$col$currrentRowNumber'] = sheet.cell(
              CellIndex.indexByString('$col$currrentRowNumber'),
            );
            cellList['$col$currrentRowNumber'].value = null;
            cellList['$col$currrentRowNumber'].cellStyle = borderedCellStyle;
          }
        } else {
          sheet.merge(
            CellIndex.indexByString('J$currrentRowNumber'),
            CellIndex.indexByString('M$currrentRowNumber'),
            customValue: TextCellValue(suspensionModel.name.toUpperCase()),
          );
          for (var col in ['J', 'K', 'L', 'M']) {
            cellList['$col$currrentRowNumber'] ??= sheet.cell(
              CellIndex.indexByString('$col$currrentRowNumber'),
            );
            cellList['$col$currrentRowNumber'].cellStyle =
                topBottomBorderCellStyle;
          }

          for (var col in ['N', 'O']) {
            cellList['$col$currrentRowNumber'] = sheet.cell(
              CellIndex.indexByString('$col$currrentRowNumber'),
            );
            cellList['$col$currrentRowNumber'].value = null;
            cellList['$col$currrentRowNumber'].cellStyle = borderedCellStyle;
          }
        }
      } else {
        // Weekday with actual attendance
        cellList['A$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('A$currrentRowNumber'),
        );
        cellList['A$currrentRowNumber'].value = IntCellValue(day);
        cellList['A$currrentRowNumber'].cellStyle = borderedCellStyle;

        cellList['B$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('B$currrentRowNumber'),
        );
        cellList['B$currrentRowNumber'].value = TextCellValue(amIn);
        cellList['B$currrentRowNumber'].cellStyle = borderedCellStyle;

        cellList['C$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('C$currrentRowNumber'),
        );
        cellList['C$currrentRowNumber'].value = TextCellValue(amOut);
        cellList['C$currrentRowNumber'].cellStyle = borderedCellStyle;

        cellList['D$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('D$currrentRowNumber'),
        );
        cellList['D$currrentRowNumber'].value = TextCellValue(pmIn);
        cellList['D$currrentRowNumber'].cellStyle = borderedCellStyle;

        cellList['E$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('E$currrentRowNumber'),
        );
        cellList['E$currrentRowNumber'].value = TextCellValue(pmOut);
        cellList['E$currrentRowNumber'].cellStyle = borderedCellStyle;

        // Calculate late/undertime
        int lateHours = 0;
        int lateMinutes = 0;
        int undertimeHours = 0;
        int undertimeMinutes = 0;

        if (dayLogs.isEmpty) {
          // No logs for the day - apply 8 hours undertime
          undertimeHours = 8;
        } else if (dayLogs.length == 1) {
          // Only 1 time log for the day - apply 8 hours undertime
          undertimeHours = 8;
        } else if (amIn.isNotEmpty && pmOut.isNotEmpty) {
          final dateFormat = DateFormat('h:mm a');

          try {
            // Parse times with correct date
            final amInTime = dateFormat
                .parse(amIn)
                .copyWith(
                  year: currentDate.year,
                  month: currentDate.month,
                  day: currentDate.day,
                );
            final pmOutTime = dateFormat
                .parse(pmOut)
                .copyWith(
                  year: currentDate.year,
                  month: currentDate.month,
                  day: currentDate.day,
                );

            DateTime? amOutTime;
            if (amOut.isNotEmpty) {
              amOutTime = dateFormat
                  .parse(amOut)
                  .copyWith(
                    year: currentDate.year,
                    month: currentDate.month,
                    day: currentDate.day,
                  );
            }

            DateTime? pmInTime;
            if (pmIn.isNotEmpty) {
              pmInTime = dateFormat
                  .parse(pmIn)
                  .copyWith(
                    year: currentDate.year,
                    month: currentDate.month,
                    day: currentDate.day,
                  );
            }

            // Define time boundaries
            final lunchStartTime = DateTime(
              currentDate.year,
              currentDate.month,
              currentDate.day,
              12,
              0,
            );
            final lunchEndTime = DateTime(
              currentDate.year,
              currentDate.month,
              currentDate.day,
              13,
              0,
            );

            int dailyUndertimeMinutes = 0;

            // Rule: Lunch break must be between 12 PM and 1 PM.
            if (amOutTime != null && amOutTime.isBefore(lunchStartTime)) {
              dailyUndertimeMinutes +=
                  lunchStartTime.difference(amOutTime).inMinutes;
            }
            if (pmInTime != null && pmInTime.isAfter(lunchEndTime)) {
              dailyUndertimeMinutes +=
                  pmInTime.difference(lunchEndTime).inMinutes;
            }

            // Calculate rendered work hours, excluding the mandatory 1-hour lunch
            int totalWorkMinutes = 0;
            if (amOutTime != null && pmInTime != null) {
              // Has lunch break, calculate work minutes based on that.
              final effectiveAmOut =
                  amOutTime.isAfter(lunchStartTime)
                      ? lunchStartTime
                      : amOutTime;
              final morningWork = effectiveAmOut.difference(amInTime).inMinutes;

              final effectivePmIn =
                  pmInTime.isBefore(lunchEndTime) ? lunchEndTime : pmInTime;
              final afternoonWork =
                  pmOutTime.difference(effectivePmIn).inMinutes;

              totalWorkMinutes = morningWork + afternoonWork;
            } else {
              // No lunch break recorded, assume 1 hour was taken.
              // Calculate total duration and subtract 1 hour lunch
              totalWorkMinutes = pmOutTime.difference(amInTime).inMinutes - 60;
            }

            // Total required work is 8 hours (480 minutes)
            final requiredWorkMinutes = 8 * 60;
            if (totalWorkMinutes < requiredWorkMinutes) {
              dailyUndertimeMinutes += requiredWorkMinutes - totalWorkMinutes;
            }

            if (dailyUndertimeMinutes > 0) {
              undertimeHours = dailyUndertimeMinutes ~/ 60;
              undertimeMinutes = dailyUndertimeMinutes % 60;
            }
          } catch (e) {
            // Handle parsing errors by leaving late/undertime as 0
          }
        }

        // Total late/undertime for the day
        int totalDayHours = lateHours + undertimeHours;
        int totalDayMinutes = lateMinutes + undertimeMinutes;
        if (totalDayMinutes >= 60) {
          totalDayHours += totalDayMinutes ~/ 60;
          totalDayMinutes = totalDayMinutes % 60;
        }

        // Update running total (only for days with data)
        totalLateUndertimeHours += totalDayHours;
        totalLateUndertimeMinutes += totalDayMinutes;
        if (totalLateUndertimeMinutes >= 60) {
          totalLateUndertimeHours += totalLateUndertimeMinutes ~/ 60;
          totalLateUndertimeMinutes = totalLateUndertimeMinutes % 60;
        }

        // Set late/undertime for the day (blank if 0)
        cellList['F$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('F$currrentRowNumber'),
        );
        cellList['F$currrentRowNumber'].value =
            totalDayHours > 0
                ? TextCellValue(totalDayHours.toString())
                : TextCellValue('');
        cellList['F$currrentRowNumber'].cellStyle = borderedCellStyle;

        cellList['G$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('G$currrentRowNumber'),
        );
        cellList['G$currrentRowNumber'].value =
            totalDayMinutes > 0
                ? TextCellValue(totalDayMinutes.toString())
                : TextCellValue('');
        cellList['G$currrentRowNumber'].cellStyle = borderedCellStyle;

        // Mirrored columns I to O
        cellList2['I$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('I$currrentRowNumber'),
        );
        cellList2['I$currrentRowNumber'].value = IntCellValue(day);
        cellList2['I$currrentRowNumber'].cellStyle = borderedCellStyle;

        final mirrorCols = {'J': amIn, 'K': amOut, 'L': pmIn, 'M': pmOut};

        mirrorCols.forEach((col, val) {
          cellList['$col$currrentRowNumber'] = sheet.cell(
            CellIndex.indexByString('$col$currrentRowNumber'),
          );
          cellList['$col$currrentRowNumber'].value = TextCellValue(val);
          cellList['$col$currrentRowNumber'].cellStyle = borderedCellStyle;
        });

        cellList['N$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('N$currrentRowNumber'),
        );
        cellList['N$currrentRowNumber'].value =
            totalDayHours > 0
                ? TextCellValue(totalDayHours.toString())
                : TextCellValue('');
        cellList['N$currrentRowNumber'].cellStyle = borderedCellStyle;

        cellList['O$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('O$currrentRowNumber'),
        );
        cellList['O$currrentRowNumber'].value =
            totalDayMinutes > 0
                ? TextCellValue(totalDayMinutes.toString())
                : TextCellValue('');
        cellList['O$currrentRowNumber'].cellStyle = borderedCellStyle;
      }
    } else {
      // This day should be blank (not included in the export period)
      // Still show the day number but leave all other cells empty
      cellList['A$currrentRowNumber'] = sheet.cell(
        CellIndex.indexByString('A$currrentRowNumber'),
      );
      cellList['A$currrentRowNumber'].value = IntCellValue(day);
      cellList['A$currrentRowNumber'].cellStyle = borderedCellStyle;

      // For weekdays, show blank cells
      if (!isWeekend) {
        // AM In
        cellList['B$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('B$currrentRowNumber'),
        );
        cellList['B$currrentRowNumber'].value = TextCellValue('');
        cellList['B$currrentRowNumber'].cellStyle = borderedCellStyle;

        // AM Out
        cellList['C$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('C$currrentRowNumber'),
        );
        cellList['C$currrentRowNumber'].value = TextCellValue('');
        cellList['C$currrentRowNumber'].cellStyle = borderedCellStyle;

        // PM In
        cellList['D$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('D$currrentRowNumber'),
        );
        cellList['D$currrentRowNumber'].value = TextCellValue('');
        cellList['D$currrentRowNumber'].cellStyle = borderedCellStyle;

        // PM Out
        cellList['E$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('E$currrentRowNumber'),
        );
        cellList['E$currrentRowNumber'].value = TextCellValue('');
        cellList['E$currrentRowNumber'].cellStyle = borderedCellStyle;

        // Late Hours
        cellList['F$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('F$currrentRowNumber'),
        );
        cellList['F$currrentRowNumber'].value = TextCellValue('');
        cellList['F$currrentRowNumber'].cellStyle = borderedCellStyle;

        // Late Minutes
        cellList['G$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('G$currrentRowNumber'),
        );
        cellList['G$currrentRowNumber'].value = TextCellValue('');
        cellList['G$currrentRowNumber'].cellStyle = borderedCellStyle;

        // Mirrored columns I to O
        cellList2['I$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('I$currrentRowNumber'),
        );
        cellList2['I$currrentRowNumber'].value = IntCellValue(day);
        cellList2['I$currrentRowNumber'].cellStyle = borderedCellStyle;

        // J - AM In
        cellList['J$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('J$currrentRowNumber'),
        );
        cellList['J$currrentRowNumber'].value = TextCellValue('');
        cellList['J$currrentRowNumber'].cellStyle = borderedCellStyle;

        // K - AM Out
        cellList['K$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('K$currrentRowNumber'),
        );
        cellList['K$currrentRowNumber'].value = TextCellValue('');
        cellList['K$currrentRowNumber'].cellStyle = borderedCellStyle;

        // L - PM In
        cellList['L$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('L$currrentRowNumber'),
        );
        cellList['L$currrentRowNumber'].value = TextCellValue('');
        cellList['L$currrentRowNumber'].cellStyle = borderedCellStyle;

        // M - PM Out
        cellList['M$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('M$currrentRowNumber'),
        );
        cellList['M$currrentRowNumber'].value = TextCellValue('');
        cellList['M$currrentRowNumber'].cellStyle = borderedCellStyle;

        // N - Late Hours
        cellList['N$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('N$currrentRowNumber'),
        );
        cellList['N$currrentRowNumber'].value = TextCellValue('');
        cellList['N$currrentRowNumber'].cellStyle = borderedCellStyle;

        // O - Late Minutes
        cellList['O$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('O$currrentRowNumber'),
        );
        cellList['O$currrentRowNumber'].value = TextCellValue('');
        cellList['O$currrentRowNumber'].cellStyle = borderedCellStyle;
      } else {
        // For weekends, show the day name but leave time cells blank
        sheet.merge(
          CellIndex.indexByString('B$currrentRowNumber'),
          CellIndex.indexByString('E$currrentRowNumber'),
          customValue: TextCellValue(monthDayNames[day - 1].toUpperCase()),
        );

        for (var col in ['B', 'C', 'D', 'E', 'F', 'G']) {
          cellList['$col$currrentRowNumber'] = sheet.cell(
            CellIndex.indexByString('$col$currrentRowNumber'),
          );
          cellList['$col$currrentRowNumber'].cellStyle =
              ['B', 'F', 'G'].contains(col)
                  ? borderedCellStyle
                  : topBottomBorderCellStyle;
        }

        cellList2['I$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('I$currrentRowNumber'),
        );
        cellList2['I$currrentRowNumber'].value = IntCellValue(day);
        cellList2['I$currrentRowNumber'].cellStyle = borderedCellStyle;

        sheet.merge(
          CellIndex.indexByString('J$currrentRowNumber'),
          CellIndex.indexByString('M$currrentRowNumber'),
          customValue: TextCellValue(monthDayNames[day - 1].toUpperCase()),
        );

        for (var col in ['J', 'K', 'L', 'M', 'N', 'O']) {
          cellList['$col$currrentRowNumber'] = sheet.cell(
            CellIndex.indexByString('$col$currrentRowNumber'),
          );
          cellList['$col$currrentRowNumber'].cellStyle =
              ['J', 'N', 'O'].contains(col)
                  ? borderedCellStyle
                  : topBottomBorderCellStyle;
        }
      }
    }

    startingRowNumber++;
  }

  // Build total row section
  buildTotalRowSection(
    sheet,
    startingRowNumber,
    totalLateUndertimeHours,
    totalLateUndertimeMinutes,
    cellList,
  );

  // Build certification section
  buildCertificationSection(
    sheet,
    startingRowNumber,
    fullName,
    position,
    supervisor,
    supervisorDesignation,
    cellList,
    profile.sectionCode,
  );

  // Apply column widths
  applyColumnWidths(sheet);

  // Save XLSX
  var bytes = excel.encode();
  if (bytes == null) return null;

  final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  final fileName =
      'dtr_${selectedDate.month}_${selectedDate.year}_$timestamp.xlsx';
  fileExists = false;

  if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = join(directory.path, fileName);
    final file =
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes);

    fileExists = await file.exists();

    if (fileExists && Platform.isMacOS) {
      await Process.run('open', [file.path]);
    } else if (fileExists && Platform.isWindows) {
      await Process.run('explorer', [file.path]);
    }
  }

  // For Android & iOS
  if (Platform.isAndroid || Platform.isIOS) {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = join(directory.path, fileName);
    final file =
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes);

    fileExists = await file.exists();
    return fileExists ? file.path : null;
  }
  return null;
}
