import 'dart:io';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:path/path.dart';
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
) async {
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
  String supervisor =
      profile.section ==
              'y78rsxd4495cz25' // Hardcode for now
          ? 'HON. ROWENA M. MACALINTAL, ASEC'
          : 'JOHN S. CALIDGUID, RSW, MPA';
  String supervisorDesignation =
      profile.section ==
              'y78rsxd4495cz25' // Hardcode for now
          ? 'Deputy Director for Operations and Services'
          : 'Officer-in-charge, SWO IV';

  // Headers
  String monthYearText =
      'FOR THE MONTH OF ${monthName.toUpperCase()} ${currentYear.toString()}';

  // Build header section
  buildHeaderSection(sheet, fullName, monthYearText);

  // Days
  var monthDayNames = getDayNamesInMonth(currentYear, currentMonth);
  var startingDay = 1;
  var startingRowNumber = 13;

  Map<String, dynamic> cellList = {};
  Map<String, dynamic> cellList2 = {};

  int totalLateUndertimeHours = 0;
  int totalLateUndertimeMinutes = 0;

  for (var monthDayName in monthDayNames) {
    var currrentRowNumber = startingRowNumber.toString();
    final isWeekend = monthDayName == 'Saturday' || monthDayName == 'Sunday';

    final currentDate = DateTime(currentYear, currentMonth, startingDay);
    final isHoliday = holidayMap.containsKey(currentDate);
    final holidayName = holidayMap[currentDate];

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
      cellList['A$currrentRowNumber'].value = IntCellValue(startingDay);
      cellList['A$currrentRowNumber'].cellStyle = borderedCellStyle;

      sheet.merge(
        CellIndex.indexByString('B$currrentRowNumber'),
        CellIndex.indexByString('E$currrentRowNumber'),
        customValue: TextCellValue(monthDayName.toUpperCase()),
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
      cellList2['I$currrentRowNumber'].value = IntCellValue(startingDay);
      cellList2['I$currrentRowNumber'].cellStyle = borderedCellStyle;

      sheet.merge(
        CellIndex.indexByString('J$currrentRowNumber'),
        CellIndex.indexByString('M$currrentRowNumber'),
        customValue: TextCellValue(monthDayName.toUpperCase()),
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
    } else if (isHoliday) {
      // Holiday format
      cellList['A$currrentRowNumber'] = sheet.cell(
        CellIndex.indexByString('A$currrentRowNumber'),
      );
      cellList['A$currrentRowNumber'].value = IntCellValue(startingDay);
      cellList['A$currrentRowNumber'].cellStyle = borderedCellStyle;

      sheet.merge(
        CellIndex.indexByString('B$currrentRowNumber'),
        CellIndex.indexByString('E$currrentRowNumber'),
        customValue: TextCellValue(holidayName!.toUpperCase()),
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
      cellList2['I$currrentRowNumber'].value = IntCellValue(startingDay);
      cellList2['I$currrentRowNumber'].cellStyle = borderedCellStyle;

      sheet.merge(
        CellIndex.indexByString('J$currrentRowNumber'),
        CellIndex.indexByString('M$currrentRowNumber'),
        customValue: TextCellValue(holidayName.toUpperCase()),
      );

      for (var col in ['B', 'C', 'D', 'E']) {
        cellList['$col$currrentRowNumber'] ??= sheet.cell(
          CellIndex.indexByString('$col$currrentRowNumber'),
        );
        cellList['$col$currrentRowNumber'].cellStyle = topBottomBorderCellStyle;
      }

      for (var col in ['J', 'K', 'L', 'M']) {
        cellList['$col$currrentRowNumber'] ??= sheet.cell(
          CellIndex.indexByString('$col$currrentRowNumber'),
        );
        cellList['$col$currrentRowNumber'].cellStyle = topBottomBorderCellStyle;
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
      cellList['A$currrentRowNumber'].value = IntCellValue(startingDay);
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
      cellList2['I$currrentRowNumber'].value = IntCellValue(startingDay);
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
      cellList['A$currrentRowNumber'].value = IntCellValue(startingDay);
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

      if (amIn.isNotEmpty && pmOut.isNotEmpty) {
        final dateFormat = DateFormat('h:mm a');
        final isMonday = monthDayName == 'Monday';
        final isWFHHalfDay =
            isWFH && dateFormat.parse(amIn).hour >= 12; // 12:00 PM or later

        final earliestInTime = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          7,
          0,
        );
        final expectedInTime =
            isWFHHalfDay
                ? DateTime(
                  currentDate.year,
                  currentDate.month,
                  currentDate.day,
                  12,
                  0,
                )
                : DateTime(
                  currentDate.year,
                  currentDate.month,
                  currentDate.day,
                  isMonday ? 9 : 9,
                  isMonday ? 0 : 30,
                );
        final minOutTime = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          16,
          0,
        );
        final maxOutTime = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          isMonday ? 18 : 18,
          isMonday ? 0 : 30,
        );

        try {
          // Parse times with correct date
          var amInTime = dateFormat
              .parse(amIn)
              .copyWith(
                year: currentDate.year,
                month: currentDate.month,
                day: currentDate.day,
              );
          var pmOutTime = dateFormat
              .parse(pmOut)
              .copyWith(
                year: currentDate.year,
                month: currentDate.month,
                day: currentDate.day,
              );

          // Adjust for PM/AM times
          if (!isWFHHalfDay && amInTime.hour >= 12) {
            amInTime = amInTime.add(Duration(days: 1));
          }
          if (pmOutTime.hour < 12) {
            pmOutTime = pmOutTime.add(Duration(days: 1));
          }

          // Cap time-in at 7:00 AM for full days
          if (!isWFHHalfDay && amInTime.isBefore(earliestInTime)) {
            amInTime = earliestInTime;
          }

          // Calculate late
          if (amInTime.isAfter(expectedInTime)) {
            final difference = amInTime.difference(expectedInTime);
            final totalMinutes = difference.inMinutes;
            lateHours = totalMinutes ~/ 60;
            lateMinutes = totalMinutes % 60;
          }

          // Calculate expected out time
          final expectedOutTime =
              isWFHHalfDay
                  ? amInTime.add(Duration(hours: 4))
                  : amInTime.add(Duration(hours: 8));
          final effectiveOutTime =
              isWFHHalfDay
                  ? expectedOutTime.isAfter(minOutTime)
                      ? expectedOutTime
                      : minOutTime
                  : expectedOutTime.isAfter(minOutTime)
                  ? expectedOutTime
                  : minOutTime;

          // Cap logout time at maxOutTime
          final effectivePmOutTime =
              pmOutTime.isAfter(maxOutTime) ? maxOutTime : pmOutTime;

          // Calculate undertime
          if (effectivePmOutTime.isBefore(effectiveOutTime)) {
            final difference = effectiveOutTime.difference(effectivePmOutTime);
            final totalMinutes = difference.inMinutes;
            undertimeHours = totalMinutes ~/ 60;
            undertimeMinutes = totalMinutes % 60;
          }

          // Calculate lunch overbreak (non-WFH only)
          if (!isWFH && amOut.isNotEmpty && pmIn.isNotEmpty) {
            try {
              final amOutTime = dateFormat
                  .parse(amOut)
                  .copyWith(
                    year: currentDate.year,
                    month: currentDate.month,
                    day: currentDate.day,
                  );
              final pmInTime = dateFormat
                  .parse(pmIn)
                  .copyWith(
                    year: currentDate.year,
                    month: currentDate.month,
                    day: currentDate.day,
                  );
              final lunchDuration = pmInTime.difference(amOutTime).inMinutes;
              if (lunchDuration > 60) {
                final overbreakMinutes = lunchDuration - 60;
                undertimeHours += overbreakMinutes ~/ 60;
                undertimeMinutes += overbreakMinutes % 60;
              }
            } catch (e) {
              // Skip overbreak if parsing fails
            }
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

      // Update running total
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
      cellList2['I$currrentRowNumber'].value = IntCellValue(startingDay);
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

    startingDay++;
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
    final downloadPath = await getPlatformDownloadPath();
    final file =
        File(join(downloadPath!, fileName))
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
    final downloadPath = await getPlatformDownloadPath();
    final filePath = join(downloadPath!, fileName);
    final file =
        File(filePath)
          ..createSync(recursive: true)
          ..writeAsBytesSync(bytes);

    fileExists = await file.exists();
    return fileExists ? file.path : null;
  }
  return null;
}
