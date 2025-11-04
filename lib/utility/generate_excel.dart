import 'dart:io';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:racconnect/data/models/attendance_model.dart';
import 'package:racconnect/data/models/profile_model.dart';
import 'package:racconnect/data/models/suspension_model.dart';
import 'package:flutter/foundation.dart'; // For error logging

import 'constants.dart';
import 'excel_utils.dart';
import 'excel_helpers.dart';

String formatSuspensionName(String originalName, bool isHalfday) {
  if (isHalfday) {
    if (originalName.toLowerCase().contains('morning')) {
      return 'AM Suspension';
    } else if (originalName.toLowerCase().contains('afternoon')) {
      return 'PM Suspension';
    }
  }
  return originalName;
}

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
  try {


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
    String fullName =
        '$firstName $middleInitial $lastName'.trim().toUpperCase();

    String position = profile.position;
    String supervisor;
    String supervisorDesignation;

    supervisor =
        profile.sectionCode == 'OIC'
            ? 'ROWENA M. MACALINTAL, ASEC'
            : 'JOHN S. CALIDGUID, RSW, MPA';
    supervisorDesignation =
        profile.sectionCode == 'OIC'
            ? 'Deputy Executive Director for Operations and Services'
            : 'Officer-in-charge, Social Welfare Officer IV';

    String monthYearText =
        'FOR THE MONTH OF ${monthName.toUpperCase()} ${currentYear.toString()}';

    buildHeaderSection(sheet, fullName, monthYearText);

    var monthDayNames = getDayNamesInMonth(currentYear, currentMonth);
    var lastDay = DateTime(currentYear, currentMonth + 1, 0).day;
    var startingRowNumber = 13;

    Set<DateTime> daysWithData = {};
    if (startDate != null && endDate != null) {
      for (int day = startDate.day; day <= endDate.day; day++) {
        daysWithData.add(DateTime(startDate.year, startDate.month, day));
      }
    } else {
      for (int day = 1; day <= lastDay; day++) {
        daysWithData.add(DateTime(currentYear, currentMonth, day));
      }
    }

    Map<String, dynamic> cellList = {};
    Map<String, dynamic> cellList2 = {};

    int totalLateUndertimeHours = 0;
    int totalLateUndertimeMinutes = 0;

    for (int day = 1; day <= lastDay; day++) {
      var currrentRowNumber = startingRowNumber.toString();
      final currentDate = DateTime(currentYear, currentMonth, day);
      final isWeekend =
          monthDayNames[day - 1] == 'Saturday' ||
          monthDayNames[day - 1] == 'Sunday';

      final shouldHaveData = daysWithData.contains(currentDate);

      if (shouldHaveData) {
        final isHoliday = holidayMap.containsKey(currentDate);
        final holidayName = holidayMap[currentDate];

        final isLeave = leaveMap.containsKey(currentDate);
        final leaveName = leaveMap[currentDate];

        final isTravel = travelMap.containsKey(currentDate);
        final travelName = travelMap[currentDate];

        final effectiveHoliday = isHoliday || isLeave || isTravel;
        final effectiveHolidayName =
            isHoliday
                ? holidayName
                : (isLeave ? leaveName : (isTravel ? travelName : null));

        final dayLogs =
            monthlyAttendance.where((log) {
              return log.timestamp.year == currentDate.year &&
                  log.timestamp.month == currentDate.month &&
                  log.timestamp.day == currentDate.day;
            }).toList();

        final logTimes = extractLogTimes(dayLogs);
        // Check if day should be considered WFH: only if there are WFH logs and NO biometric logs
        final hasBiometrics = dayLogs.any(
          (log) => log.type.toLowerCase() == 'biometrics',
        );
        final hasWFH = dayLogs.any(
          (log) => log.type.toLowerCase().contains('wfh'),
        );
        bool isWFH =
            hasWFH &&
            !hasBiometrics; // For calculations only, biometrics take priority
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

          for (var col in ['B', 'C', 'D', 'E']) {
            cellList['$col$currrentRowNumber'] ??= sheet.cell(
              CellIndex.indexByString('$col$currrentRowNumber'),
            );
            cellList['$col$currrentRowNumber'].cellStyle =
                greyedTopBottomBorderCellStyle;
          }

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
            customValue: TextCellValue(monthDayNames[day - 1].toUpperCase()),
          );

          for (var col in ['J', 'K', 'L', 'M']) {
            cellList['$col$currrentRowNumber'] ??= sheet.cell(
              CellIndex.indexByString('$col$currrentRowNumber'),
            );
            cellList['$col$currrentRowNumber'].cellStyle =
                greyedTopBottomBorderCellStyle;
          }

          for (var col in ['N', 'O']) {
            cellList['$col$currrentRowNumber'] = sheet.cell(
              CellIndex.indexByString('$col$currrentRowNumber'),
            );
            cellList['$col$currrentRowNumber'].value = null;
            cellList['$col$currrentRowNumber'].cellStyle = borderedCellStyle;
          }
        } else if (effectiveHoliday) {
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

          for (var col in ['B', 'C', 'D', 'E']) {
            cellList['$col$currrentRowNumber'] ??= sheet.cell(
              CellIndex.indexByString('$col$currrentRowNumber'),
            );
            cellList['$col$currrentRowNumber'].cellStyle =
                greyedTopBottomBorderCellStyle;
          }

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

          for (var col in ['J', 'K', 'L', 'M']) {
            cellList['$col$currrentRowNumber'] ??= sheet.cell(
              CellIndex.indexByString('$col$currrentRowNumber'),
            );
            cellList['$col$currrentRowNumber'].cellStyle =
                greyedTopBottomBorderCellStyle;
          }

          for (var col in ['N', 'O']) {
            cellList['$col$currrentRowNumber'] = sheet.cell(
              CellIndex.indexByString('$col$currrentRowNumber'),
            );
            cellList['$col$currrentRowNumber'].value = null;
            cellList['$col$currrentRowNumber'].cellStyle = borderedCellStyle;
          }
        } else if (isSuspension) {
          // Calculate late/undertime
          int lateHours = 0;
          int lateMinutes = 0;
          int undertimeHours = 0;
          int undertimeMinutes = 0;

          cellList['A$currrentRowNumber'] = sheet.cell(
            CellIndex.indexByString('A$currrentRowNumber'),
          );
          cellList['A$currrentRowNumber'].value = IntCellValue(day);
          cellList['A$currrentRowNumber'].cellStyle = borderedCellStyle;

          if (suspensionModel!.isHalfday) {
            if (amIn.isNotEmpty) {
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
                CellIndex.indexByString(
                  'E$currrentRowNumber',
                ), // Merges D and E
                customValue: TextCellValue(
                  formatSuspensionName(
                    suspensionModel.name,
                    suspensionModel.isHalfday,
                  ).toUpperCase(),
                ),
              );
              for (var col in ['D', 'E']) {
                // Apply styles to merged cells
                cellList['$col$currrentRowNumber'] ??= sheet.cell(
                  CellIndex.indexByString('$col$currrentRowNumber'),
                );
                cellList['$col$currrentRowNumber'].cellStyle =
                    greyedTopBottomBorderCellStyle;
              }
            } else {
              // Half-day suspension with no time-in
              final eightAm = DateTime(currentYear, currentMonth, day, 8, 0);
              final suspensionTime = DateTime(
                currentYear,
                currentMonth,
                day,
                suspensionModel.datetime.hour,
                suspensionModel.datetime.minute,
              );
              int dailyUndertimeMinutes =
                  suspensionTime.difference(eightAm).inMinutes;

              if (suspensionTime.hour >= 13) {
                dailyUndertimeMinutes -= 60; // Deduct 1 hour for lunch
              }

              if (dailyUndertimeMinutes > 0) {
                undertimeHours = dailyUndertimeMinutes ~/ 60;
                undertimeMinutes = dailyUndertimeMinutes % 60;
              }

              // AM Arrival and Departure are blank
              cellList['B$currrentRowNumber'] = sheet.cell(
                CellIndex.indexByString('B$currrentRowNumber'),
              );
              cellList['B$currrentRowNumber'].value = TextCellValue('');
              cellList['B$currrentRowNumber'].cellStyle = borderedCellStyle;

              cellList['C$currrentRowNumber'] = sheet.cell(
                CellIndex.indexByString('C$currrentRowNumber'),
              );
              cellList['C$currrentRowNumber'].value = TextCellValue('');
              cellList['C$currrentRowNumber'].cellStyle = borderedCellStyle;

              // Merge PM cells and display suspension name
              sheet.merge(
                CellIndex.indexByString('D$currrentRowNumber'),
                CellIndex.indexByString(
                  'E$currrentRowNumber',
                ), // Merges D and E
                customValue: TextCellValue(
                  formatSuspensionName(
                    suspensionModel.name,
                    suspensionModel.isHalfday,
                  ).toUpperCase(),
                ),
              );
              for (var col in ['D', 'E']) {
                // Apply styles to merged cells
                cellList['$col$currrentRowNumber'] ??= sheet.cell(
                  CellIndex.indexByString('$col$currrentRowNumber'),
                );
                cellList['$col$currrentRowNumber'].cellStyle =
                    greyedTopBottomBorderCellStyle;
              }
            }
          } else {
            // Full-day suspension
            sheet.merge(
              CellIndex.indexByString('B$currrentRowNumber'),
              CellIndex.indexByString(
                'E$currrentRowNumber',
              ), // Merges B, C, D, E
              customValue: TextCellValue(
                formatSuspensionName(
                  suspensionModel.name,
                  suspensionModel.isHalfday,
                ).toUpperCase(),
              ),
            );
            for (var col in ['B', 'C', 'D', 'E']) {
              // Apply styles to merged cells
              cellList['$col$currrentRowNumber'] ??= sheet.cell(
                CellIndex.indexByString('$col$currrentRowNumber'),
              );
              cellList['$col$currrentRowNumber'].cellStyle =
                  greyedTopBottomBorderCellStyle;
            }
          }

          // Total late/undertime for the day
          // For flexitime system, we use max of late or undertime rather than sum
          // since arriving late in flexitime system might be offset by working required hours
          int totalDayHours;
          int totalDayMinutes;
          
          // For flexitime, use the maximum of late or undertime, not sum
          if (lateHours > 0 || lateMinutes > 0) {
            // Convert both to minutes for comparison
            int lateTotalMinutes = lateHours * 60 + lateMinutes;
            int undertimeTotalMinutes = undertimeHours * 60 + undertimeMinutes;
            
            // Use the maximum of the two to avoid double-penalizing in flexitime
            int maxMinutes = lateTotalMinutes > undertimeTotalMinutes ? lateTotalMinutes : undertimeTotalMinutes;
            
            totalDayHours = maxMinutes ~/ 60;
            totalDayMinutes = maxMinutes % 60;
          } else {
            // If no late time, use undertime as-is
            totalDayHours = undertimeHours;
            totalDayMinutes = undertimeMinutes;
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

          // Mirrored columns I to O (similar to holiday logic)
          cellList2['I$currrentRowNumber'] = sheet.cell(
            CellIndex.indexByString('I$currrentRowNumber'),
          );
          cellList2['I$currrentRowNumber'].value = IntCellValue(day);
          cellList2['I$currrentRowNumber'].cellStyle = borderedCellStyle;

          if (suspensionModel.isHalfday) {
            if (amIn.isNotEmpty) {
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
                customValue: TextCellValue(
                  formatSuspensionName(
                    suspensionModel.name,
                    suspensionModel.isHalfday,
                  ).toUpperCase(),
                ),
              );
              for (var col in ['L', 'M']) {
                cellList['$col$currrentRowNumber'] ??= sheet.cell(
                  CellIndex.indexByString('$col$currrentRowNumber'),
                );
                cellList['$col$currrentRowNumber'].cellStyle =
                    greyedTopBottomBorderCellStyle;
              }
            } else {
              // Half-day suspension with no time-in
              cellList['J$currrentRowNumber'] = sheet.cell(
                CellIndex.indexByString('J$currrentRowNumber'),
              );
              cellList['J$currrentRowNumber'].value = TextCellValue('');
              cellList['J$currrentRowNumber'].cellStyle = borderedCellStyle;

              cellList['K$currrentRowNumber'] = sheet.cell(
                CellIndex.indexByString('K$currrentRowNumber'),
              );
              cellList['K$currrentRowNumber'].value = TextCellValue('');
              cellList['K$currrentRowNumber'].cellStyle = borderedCellStyle;

              sheet.merge(
                CellIndex.indexByString('L$currrentRowNumber'),
                CellIndex.indexByString('M$currrentRowNumber'),
                customValue: TextCellValue(
                  formatSuspensionName(
                    suspensionModel.name,
                    suspensionModel.isHalfday,
                  ).toUpperCase(),
                ),
              );
              for (var col in ['L', 'M']) {
                cellList['$col$currrentRowNumber'] ??= sheet.cell(
                  CellIndex.indexByString('$col$currrentRowNumber'),
                );
                cellList['$col$currrentRowNumber'].cellStyle =
                    greyedTopBottomBorderCellStyle;
              }
            }
          } else {
            sheet.merge(
              CellIndex.indexByString('J$currrentRowNumber'),
              CellIndex.indexByString('M$currrentRowNumber'),
              customValue: TextCellValue(
                formatSuspensionName(
                  suspensionModel.name,
                  suspensionModel.isHalfday,
                ).toUpperCase(),
              ),
            );
            for (var col in ['J', 'K', 'L', 'M']) {
              cellList['$col$currrentRowNumber'] ??= sheet.cell(
                CellIndex.indexByString('$col$currrentRowNumber'),
              );
              cellList['$col$currrentRowNumber'].cellStyle =
                  greyedTopBottomBorderCellStyle;
            }
          }

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
        } else {
          // Weekday with actual attendance
          cellList['A$currrentRowNumber'] = sheet.cell(
            CellIndex.indexByString('A$currrentRowNumber'),
          );
          cellList['A$currrentRowNumber'].value = IntCellValue(day);
          cellList['A$currrentRowNumber'].cellStyle = borderedCellStyle;

          // Check if this should be treated as an afternoon half-day for visual display
          // (first arrival at or after 12 PM, but preserve original values for calculations)
          bool displayAsAfternoonHalfDay = false;
          if (amIn.isNotEmpty) {
            try {
              final firstArrivalTime = dateFormat.parse(amIn);
              if (firstArrivalTime.hour >= 12) { // 12 PM or later
                displayAsAfternoonHalfDay = true;
              }
            } catch (e) {
              // If parsing fails, continue with normal display
            }
          }
          
          if (displayAsAfternoonHalfDay) {
            // For visual display, if first arrival is at or after 12 PM, 
            // show it in PM Arrival (D) instead of AM Arrival (B)
            cellList['B$currrentRowNumber'] = sheet.cell(
              CellIndex.indexByString('B$currrentRowNumber'),
            );
            cellList['B$currrentRowNumber'].value = TextCellValue(''); // No AM arrival
            cellList['B$currrentRowNumber'].cellStyle = borderedCellStyle;

            cellList['C$currrentRowNumber'] = sheet.cell(
              CellIndex.indexByString('C$currrentRowNumber'),
            );
            cellList['C$currrentRowNumber'].value = TextCellValue(''); // No AM departure
            cellList['C$currrentRowNumber'].cellStyle = borderedCellStyle;

            cellList['D$currrentRowNumber'] = sheet.cell(
              CellIndex.indexByString('D$currrentRowNumber'),
            );
            cellList['D$currrentRowNumber'].value = TextCellValue(amIn); // First arrival in PM Arrival
            cellList['D$currrentRowNumber'].cellStyle = borderedCellStyle;

            cellList['E$currrentRowNumber'] = sheet.cell(
              CellIndex.indexByString('E$currrentRowNumber'),
            );
            cellList['E$currrentRowNumber'].value = TextCellValue(pmOut); // PM departure
            cellList['E$currrentRowNumber'].cellStyle = borderedCellStyle;
          } else {
            // Normal display for regular days
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
          }

          // Calculate late/undertime
          int lateHours = 0;
          int lateMinutes = 0;
          int undertimeHours = 0;
          int undertimeMinutes = 0;

          if (dayLogs.isEmpty) {
            // No logs for the day - apply 8 hours undertime (for net work hours)
            undertimeHours = 8;
          } else if (dayLogs.length == 1) {
            // Only 1 time log for the day - apply 8 hours undertime (for net work hours)
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

              // Determine grace period based on day of week
              int graceHour = 9; // Default for non-Monday
              int graceMinute = 30; // Default for non-Monday
              if (currentDate.weekday == DateTime.monday) {
                // Monday: No late until 9AM (work hours start at 7AM, but grace until 9AM)
                graceHour = 9;
                graceMinute = 0;
              }

              final graceTime = DateTime(
                currentDate.year,
                currentDate.month,
                currentDate.day,
                graceHour,
                graceMinute,
              );

              // Calculate late minutes
              int calculatedLateMinutes = 0;
              if (amInTime.isAfter(graceTime)) {
                calculatedLateMinutes =
                    amInTime.difference(graceTime).inMinutes;
              }

              // Calculate undertime based on required hours vs actual hours worked
              int dailyUndertimeMinutes = 0;

              // New rule: if login is at or after 12 PM
              if (amInTime.hour >= 12) {
                // If arrival is at or after 12 PM, employee missed the morning shift (4 hours of work)
                // Starting base undertime is 4 hours for missing morning shift
                int baseUndertimeMinutes =
                    4 * 60; // 4 hours undertime for missing morning shift

                // For afternoon arrivals, don't count as late since they're not expected in the morning
                calculatedLateMinutes = 0; // Reset late minutes to zero

                // Calculate afternoon work: from 1 PM to their departure time
                // They need to work until 5 PM (4 hours) to fulfill afternoon requirement
                final requiredEndTime = DateTime(
                  currentDate.year,
                  currentDate.month,
                  currentDate.day,
                  17,
                  0,
                ); // 5:00 PM

                // Effective start time for afternoon work is 1 PM (regardless of when they actually arrived)
                final effectiveWorkStart = DateTime(
                  currentDate.year,
                  currentDate.month,
                  currentDate.day,
                  13,
                  0,
                ); // 1:00 PM

                if (pmOutTime.isBefore(requiredEndTime)) {
                  // If they left before 5 PM, calculate additional undertime
                  int actualAfternoonMinutes =
                      pmOutTime.difference(effectiveWorkStart).inMinutes;
                  int requiredAfternoonMinutes =
                      4 * 60; // 4 hours afternoon work required
                  int additionalUndertimeMinutes =
                      requiredAfternoonMinutes - actualAfternoonMinutes;

                  if (additionalUndertimeMinutes > 0) {
                    dailyUndertimeMinutes =
                        baseUndertimeMinutes + additionalUndertimeMinutes;
                  } else {
                    dailyUndertimeMinutes =
                        baseUndertimeMinutes; // In case they somehow worked negative time
                  }
                } else {
                  // If they left at or after 5 PM, no additional undertime for afternoon
                  dailyUndertimeMinutes = baseUndertimeMinutes;
                }

                if (calculatedLateMinutes > 0) {
                  lateHours = calculatedLateMinutes ~/ 60;
                  lateMinutes = calculatedLateMinutes % 60;
                } else {
                  lateHours = 0;
                  lateMinutes = 0;
                }

                if (dailyUndertimeMinutes > 0) {
                  undertimeHours = dailyUndertimeMinutes ~/ 60;
                  undertimeMinutes = dailyUndertimeMinutes % 60;
                } else {
                  undertimeHours = 0;
                  undertimeMinutes = 0;
                }
              } else {
                // For morning login, calculate total work time
                int totalWorkMinutes = 0;

                // Rule: Lunch break must be between 12 PM and 1 PM.
                if (amOutTime != null && amOutTime.isBefore(lunchStartTime)) {
                  dailyUndertimeMinutes +=
                      lunchStartTime.difference(amOutTime).inMinutes;
                }
                if (pmInTime != null && pmInTime.isAfter(lunchEndTime)) {
                  dailyUndertimeMinutes +=
                      pmInTime.difference(lunchEndTime).inMinutes;
                }

                // Calculate rendered work hours, handling lunch break properly
                if (amOutTime != null && pmInTime != null) {
                  // Has both lunch out and in records, calculate work minutes based on that.
                  final effectiveAmOut =
                      amOutTime.isAfter(lunchStartTime)
                          ? lunchStartTime
                          : amOutTime;
                  final morningWork =
                      effectiveAmOut.difference(amInTime).inMinutes;

                  final effectivePmIn =
                      pmInTime.isBefore(lunchEndTime) ? lunchEndTime : pmInTime;
                  final afternoonWork =
                      pmOutTime.difference(effectivePmIn).inMinutes;

                  totalWorkMinutes = morningWork + afternoonWork;
                } else if (amOutTime != null && pmInTime == null) {
                  // Only lunch out recorded, treat as lunch 12-1PM
                  final effectiveAmOut =
                      amOutTime.isAfter(lunchStartTime)
                          ? lunchStartTime
                          : amOutTime;
                  final morningWork =
                      effectiveAmOut.difference(amInTime).inMinutes;

                  // If logged out after 1PM but no PM in record, assume lunch 12-1PM
                  final effectivePmIn =
                      pmOutTime.isAfter(lunchEndTime)
                          ? lunchEndTime
                          : pmOutTime;
                  final afternoonWork =
                      pmOutTime.difference(effectivePmIn).inMinutes;

                  totalWorkMinutes = morningWork + afternoonWork;
                } else if (amOutTime == null && pmInTime != null) {
                  // Only lunch in recorded, treat as lunch 12-1PM
                  // If logged out after 1PM, assume lunch 12-1PM
                  final effectiveAmOut =
                      pmOutTime.isAfter(lunchStartTime)
                          ? lunchStartTime
                          : pmOutTime;
                  final morningWork =
                      effectiveAmOut.difference(amInTime).inMinutes;

                  final effectivePmIn =
                      pmInTime.isBefore(lunchEndTime) ? lunchEndTime : pmInTime;
                  final afternoonWork =
                      pmOutTime.difference(effectivePmIn).inMinutes;

                  totalWorkMinutes = morningWork + afternoonWork;
                } else {
                  // No lunch break records at all
                  if (amInTime.isBefore(lunchStartTime) &&
                      pmOutTime.isAfter(lunchEndTime)) {
                    // If employee arrived before 12PM and left after 1PM,
                    // automatically count standard lunch break from 12PM-1PM
                    final morningWork =
                        lunchStartTime.difference(amInTime).inMinutes;
                    final afternoonWork =
                        pmOutTime.difference(lunchEndTime).inMinutes;
                    totalWorkMinutes = morningWork + afternoonWork;
                  } else if (amInTime.isBefore(lunchStartTime) &&
                      pmOutTime.isAfter(lunchStartTime) &&
                      pmOutTime.isBefore(lunchEndTime)) {
                    // If employee arrived before 12PM and left between 12PM-1PM,
                    // they didn't take the full lunch break, so calculate accordingly
                    totalWorkMinutes = pmOutTime.difference(amInTime).inMinutes;
                  } else if (amInTime.isAfter(lunchEndTime)) {
                    // If employee arrived after 1PM, they missed the morning work and lunch
                    final afternoonWork =
                        pmOutTime.difference(amInTime).inMinutes;
                    totalWorkMinutes = afternoonWork;
                  } else {
                    // Other scenarios
                    totalWorkMinutes = pmOutTime.difference(amInTime).inMinutes;
                  }
                }

                // Check against required 8 hours net work time
                final requiredWorkMinutes = 8 * 60;
                if (totalWorkMinutes < requiredWorkMinutes) {
                  dailyUndertimeMinutes =
                      (requiredWorkMinutes - totalWorkMinutes);
                }

                if (calculatedLateMinutes > 0) {
                  lateHours = calculatedLateMinutes ~/ 60;
                  lateMinutes = calculatedLateMinutes % 60;
                } else {
                  lateHours = 0;
                  lateMinutes = 0;
                }

                if (dailyUndertimeMinutes > 0) {
                  undertimeHours = dailyUndertimeMinutes ~/ 60;
                  undertimeMinutes = dailyUndertimeMinutes % 60;
                } else {
                  undertimeHours = 0;
                  undertimeMinutes = 0;
                }
              }
            } catch (e) {
              // Handle parsing errors by leaving late/undertime as 0
            }
          }

          // Total late/undertime for the day
          // For flexitime system, we use max of late or undertime rather than sum
          // since arriving late in flexitime system might be offset by working required hours
          int totalDayHours;
          int totalDayMinutes;
          
          // For flexitime, use the maximum of late or undertime, not sum
          if (lateHours > 0 || lateMinutes > 0) {
            // Convert both to minutes for comparison
            int lateTotalMinutes = lateHours * 60 + lateMinutes;
            int undertimeTotalMinutes = undertimeHours * 60 + undertimeMinutes;
            
            // Use the maximum of the two to avoid double-penalizing in flexitime
            int maxMinutes = lateTotalMinutes > undertimeTotalMinutes ? lateTotalMinutes : undertimeTotalMinutes;
            
            totalDayHours = maxMinutes ~/ 60;
            totalDayMinutes = maxMinutes % 60;
          } else {
            // If no late time, use undertime as-is
            totalDayHours = undertimeHours;
            totalDayMinutes = undertimeMinutes;
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

          // Apply same visual display logic to mirrored section
          if (displayAsAfternoonHalfDay) {
            // For visual display, if first arrival is at or after 12 PM, 
            // show it in PM Arrival (L) instead of AM Arrival (J)
            cellList['J$currrentRowNumber'] = sheet.cell(
              CellIndex.indexByString('J$currrentRowNumber'),
            );
            cellList['J$currrentRowNumber'].value = TextCellValue(''); // No AM arrival
            cellList['J$currrentRowNumber'].cellStyle = borderedCellStyle;

            cellList['K$currrentRowNumber'] = sheet.cell(
              CellIndex.indexByString('K$currrentRowNumber'),
            );
            cellList['K$currrentRowNumber'].value = TextCellValue(''); // No AM departure
            cellList['K$currrentRowNumber'].cellStyle = borderedCellStyle;

            cellList['L$currrentRowNumber'] = sheet.cell(
              CellIndex.indexByString('L$currrentRowNumber'),
            );
            cellList['L$currrentRowNumber'].value = TextCellValue(amIn); // First arrival in PM Arrival
            cellList['L$currrentRowNumber'].cellStyle = borderedCellStyle;

            cellList['M$currrentRowNumber'] = sheet.cell(
              CellIndex.indexByString('M$currrentRowNumber'),
            );
            cellList['M$currrentRowNumber'].value = TextCellValue(pmOut); // PM departure
            cellList['M$currrentRowNumber'].cellStyle = borderedCellStyle;
          } else {
            // Normal display for regular days
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

            cellList['L$currrentRowNumber'] = sheet.cell(
              CellIndex.indexByString('L$currrentRowNumber'),
            );
            cellList['L$currrentRowNumber'].value = TextCellValue(pmIn);
            cellList['L$currrentRowNumber'].cellStyle = borderedCellStyle;

            cellList['M$currrentRowNumber'] = sheet.cell(
              CellIndex.indexByString('M$currrentRowNumber'),
            );
            cellList['M$currrentRowNumber'].value = TextCellValue(pmOut);
            cellList['M$currrentRowNumber'].cellStyle = borderedCellStyle;
          }

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

          for (var col in ['B', 'C', 'D', 'E']) {
            cellList['$col$currrentRowNumber'] ??= sheet.cell(
              CellIndex.indexByString('$col$currrentRowNumber'),
            );
            cellList['$col$currrentRowNumber'].cellStyle =
                greyedTopBottomBorderCellStyle;
          }

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
            customValue: TextCellValue(monthDayNames[day - 1].toUpperCase()),
          );

          for (var col in ['J', 'K', 'L', 'M']) {
            cellList['$col$currrentRowNumber'] ??= sheet.cell(
              CellIndex.indexByString('$col$currrentRowNumber'),
            );
            cellList['$col$currrentRowNumber'].cellStyle =
                greyedTopBottomBorderCellStyle;
          }

          for (var col in ['N', 'O']) {
            cellList['$col$currrentRowNumber'] = sheet.cell(
              CellIndex.indexByString('$col$currrentRowNumber'),
            );
            cellList['$col$currrentRowNumber'].value = null;
            cellList['$col$currrentRowNumber'].cellStyle = borderedCellStyle;
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
  } catch (e) {
    if (kDebugMode) {
    }
    rethrow; // Re-throw to be handled by calling function
  }
}
