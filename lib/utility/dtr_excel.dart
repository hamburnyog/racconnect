import 'dart:io';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:racconnect/data/models/attendance_model.dart';
import 'package:racconnect/data/models/profile_model.dart';

import 'constants.dart';

Future<String?> generateExcel(
  DateTime selectedDate,
  ProfileModel profile,
  List<AttendanceModel> monthlyAttendance,
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
  String supervisor = 'JOHN S. CALIDGUID, RSW, MPA';
  String supervisorDesignation = 'Officer-in-charge, SWO IV';

  // Headers

  String monthYearText =
      'FOR THE MONTH OF ${monthName.toUpperCase()} ${currentYear.toString()}';

  var cell1 = sheet.cell(CellIndex.indexByString('A2'));
  cell1.value = TextCellValue(cscText);
  cell1.cellStyle = cscCellStyle;
  var cell2 = sheet.cell(CellIndex.indexByString('I2'));
  cell2.value = TextCellValue(cscText);
  cell2.cellStyle = cscCellStyle;

  sheet.merge(
    CellIndex.indexByString('A3'),
    CellIndex.indexByString('G3'),
    customValue: TextCellValue(naccText),
  );
  var cell3 = sheet.cell(CellIndex.indexByString('A3'));
  cell3.cellStyle = naccCellStyle;

  sheet.merge(
    CellIndex.indexByString('I3'),
    CellIndex.indexByString('O3'),
    customValue: TextCellValue(naccText),
  );
  var cell4 = sheet.cell(CellIndex.indexByString('I3'));
  cell4.cellStyle = naccCellStyle;

  sheet.merge(
    CellIndex.indexByString('A4'),
    CellIndex.indexByString('G4'),
    customValue: TextCellValue(dtrText),
  );
  var cell5 = sheet.cell(CellIndex.indexByString('A4'));
  cell5.cellStyle = dtrCellStyle;

  sheet.merge(
    CellIndex.indexByString('I4'),
    CellIndex.indexByString('O4'),
    customValue: TextCellValue(dtrText),
  );
  var cell6 = sheet.cell(CellIndex.indexByString('I4'));
  cell6.cellStyle = dtrCellStyle;

  sheet.merge(
    CellIndex.indexByString('A9'),
    CellIndex.indexByString('G9'),
    customValue: TextCellValue(fullName),
  );
  var cell7 = sheet.cell(CellIndex.indexByString('A9'));
  cell7.cellStyle = boldCellStyle;

  sheet.merge(
    CellIndex.indexByString('I9'),
    CellIndex.indexByString('O9'),
    customValue: TextCellValue(fullName),
  );
  var cell8 = sheet.cell(CellIndex.indexByString('I9'));
  cell8.cellStyle = boldCellStyle;

  sheet.merge(
    CellIndex.indexByString('A10'),
    CellIndex.indexByString('G10'),
    customValue: TextCellValue(monthYearText),
  );
  var cell9 = sheet.cell(CellIndex.indexByString('A10'));
  cell9.cellStyle = centerTextStyle;

  sheet.merge(
    CellIndex.indexByString('I10'),
    CellIndex.indexByString('O10'),
    customValue: TextCellValue(monthYearText),
  );
  var cell10 = sheet.cell(CellIndex.indexByString('I10'));
  cell10.cellStyle = centerTextStyle;

  sheet.merge(
    CellIndex.indexByString('A11'),
    CellIndex.indexByString('A12'),
    customValue: TextCellValue(daysText),
  );
  var cell11 = sheet.cell(CellIndex.indexByString('A11'));
  cell11.cellStyle = noBottomBorderCellStyle;
  var cell12 = sheet.cell(CellIndex.indexByString('A12'));
  cell12.cellStyle = noTopBorderCellStyle;

  sheet.merge(
    CellIndex.indexByString('I11'),
    CellIndex.indexByString('I12'),
    customValue: TextCellValue(daysText),
  );
  var cell13 = sheet.cell(CellIndex.indexByString('I11'));
  cell13.cellStyle = noBottomBorderCellStyle;
  var cell14 = sheet.cell(CellIndex.indexByString('I12'));
  cell14.cellStyle = noTopBorderCellStyle;

  sheet.merge(
    CellIndex.indexByString('B11'),
    CellIndex.indexByString('C11'),
    customValue: TextCellValue(amText),
  );
  var cell15 = sheet.cell(CellIndex.indexByString('B11'));
  cell15.cellStyle = noLeftBorderCellStyle;
  var cell16 = sheet.cell(CellIndex.indexByString('C11'));
  cell16.cellStyle = noLeftBorderCellStyle;

  sheet.merge(
    CellIndex.indexByString('D11'),
    CellIndex.indexByString('E11'),
    customValue: TextCellValue(pmText),
  );
  var cell17 = sheet.cell(CellIndex.indexByString('D11'));
  cell17.cellStyle = noLeftBorderCellStyle;
  var cell18 = sheet.cell(CellIndex.indexByString('E11'));
  cell18.cellStyle = noLeftBorderCellStyle;

  sheet.merge(
    CellIndex.indexByString('F11'),
    CellIndex.indexByString('G11'),
    customValue: TextCellValue(lateUndertimeText),
  );
  var cell19 = sheet.cell(CellIndex.indexByString('F11'));
  cell19.cellStyle = noLeftBorderCellStyle;
  var cell20 = sheet.cell(CellIndex.indexByString('G11'));
  cell20.cellStyle = noLeftBorderCellStyle;

  sheet.merge(
    CellIndex.indexByString('J11'),
    CellIndex.indexByString('K11'),
    customValue: TextCellValue(amText),
  );
  var cell21 = sheet.cell(CellIndex.indexByString('J11'));
  cell21.cellStyle = noLeftBorderCellStyle;
  var cell22 = sheet.cell(CellIndex.indexByString('K11'));
  cell22.cellStyle = noLeftBorderCellStyle;

  sheet.merge(
    CellIndex.indexByString('L11'),
    CellIndex.indexByString('M11'),
    customValue: TextCellValue(pmText),
  );
  var cell23 = sheet.cell(CellIndex.indexByString('L11'));
  cell23.cellStyle = noLeftBorderCellStyle;
  var cell24 = sheet.cell(CellIndex.indexByString('M11'));
  cell24.cellStyle = noLeftBorderCellStyle;

  sheet.merge(
    CellIndex.indexByString('N11'),
    CellIndex.indexByString('O11'),
    customValue: TextCellValue(lateUndertimeText),
  );
  var cell25 = sheet.cell(CellIndex.indexByString('N11'));
  cell25.cellStyle = noLeftBorderCellStyle;
  var cell26 = sheet.cell(CellIndex.indexByString('O11'));
  cell26.cellStyle = noLeftBorderCellStyle;

  var cell27 = sheet.cell(CellIndex.indexByString('B12'));
  cell27.value = TextCellValue(arrivalText);
  cell27.cellStyle = borderedCellStyle;

  var cell28 = sheet.cell(CellIndex.indexByString('C12'));
  cell28.value = TextCellValue(departureText);
  cell28.cellStyle = borderedCellStyle;

  var cell29 = sheet.cell(CellIndex.indexByString('D12'));
  cell29.value = TextCellValue(arrivalText);
  cell29.cellStyle = borderedCellStyle;

  var cell30 = sheet.cell(CellIndex.indexByString('E12'));
  cell30.value = TextCellValue(departureText);
  cell30.cellStyle = borderedCellStyle;

  var cell31 = sheet.cell(CellIndex.indexByString('F12'));
  cell31.value = TextCellValue(hoursText);
  cell31.cellStyle = borderedCellStyle;

  var cell32 = sheet.cell(CellIndex.indexByString('G12'));
  cell32.value = TextCellValue(minutesText);
  cell32.cellStyle = borderedCellStyle;

  var cell33 = sheet.cell(CellIndex.indexByString('J12'));
  cell33.value = TextCellValue(arrivalText);
  cell33.cellStyle = borderedCellStyle;

  var cell34 = sheet.cell(CellIndex.indexByString('K12'));
  cell34.value = TextCellValue(departureText);
  cell34.cellStyle = borderedCellStyle;

  var cell35 = sheet.cell(CellIndex.indexByString('L12'));
  cell35.value = TextCellValue(arrivalText);
  cell35.cellStyle = borderedCellStyle;

  var cell36 = sheet.cell(CellIndex.indexByString('M12'));
  cell36.value = TextCellValue(departureText);
  cell36.cellStyle = borderedCellStyle;

  var cell37 = sheet.cell(CellIndex.indexByString('N12'));
  cell37.value = TextCellValue(hoursText);
  cell37.cellStyle = borderedCellStyle;

  var cell38 = sheet.cell(CellIndex.indexByString('O12'));
  cell38.value = TextCellValue(minutesText);
  cell38.cellStyle = borderedCellStyle;

  // Days

  var monthDayNames = getDayNamesInMonth(currentYear, currentMonth);
  var startingDay = 1;
  var startingRowNumber = 13;

  Map<String, dynamic> cellList = {};
  Map<String, dynamic> cellList2 = {};

  for (var monthDayName in monthDayNames) {
    var currrentRowNumber = startingRowNumber.toString();
    final isWeekend = monthDayName == 'Saturday' || monthDayName == 'Sunday';

    final currentDate = DateTime(currentYear, currentMonth, startingDay);

    final dayLogs =
        monthlyAttendance.where((log) {
          return log.timestamp.year == currentDate.year &&
              log.timestamp.month == currentDate.month &&
              log.timestamp.day == currentDate.day;
        }).toList();

    final logTimes = extractLogTimes(dayLogs);
    final amIn = logTimes['amIn'] ?? '';
    final amOut = logTimes['amOut'] ?? '';
    final pmIn = logTimes['pmIn'] ?? '';
    final pmOut = logTimes['pmOut'] ?? '';

    if (isWeekend) {
      // Your weekend format (unchanged)
      // A column
      cellList['A$currrentRowNumber'] = sheet.cell(
        CellIndex.indexByString('A$currrentRowNumber'),
      );
      cellList['A$currrentRowNumber'].value = IntCellValue(startingDay);
      cellList['A$currrentRowNumber'].cellStyle = borderedCellStyle;

      // Merge B-E
      sheet.merge(
        CellIndex.indexByString('B$currrentRowNumber'),
        CellIndex.indexByString('E$currrentRowNumber'),
        customValue: TextCellValue(monthDayName.toUpperCase()),
      );

      // Border setup for weekend columns
      for (var col in ['B', 'C', 'D', 'E', 'F', 'G']) {
        cellList['$col$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('$col$currrentRowNumber'),
        );
        cellList['$col$currrentRowNumber'].cellStyle =
            ['B', 'F', 'G'].contains(col)
                ? borderedCellStyle
                : topBottomBorderCellStyle;
      }

      // I column
      cellList2['I$currrentRowNumber'] = sheet.cell(
        CellIndex.indexByString('I$currrentRowNumber'),
      );
      cellList2['I$currrentRowNumber'].value = IntCellValue(startingDay);
      cellList2['I$currrentRowNumber'].cellStyle = borderedCellStyle;

      // Merge J-M
      sheet.merge(
        CellIndex.indexByString('J$currrentRowNumber'),
        CellIndex.indexByString('M$currrentRowNumber'),
        customValue: TextCellValue(monthDayName.toUpperCase()),
      );

      // Border setup for weekend mirrored columns
      for (var col in ['J', 'K', 'L', 'M', 'N', 'O']) {
        cellList['$col$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('$col$currrentRowNumber'),
        );
        cellList['$col$currrentRowNumber'].cellStyle =
            ['J', 'N', 'O'].contains(col)
                ? borderedCellStyle
                : topBottomBorderCellStyle;
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
      cellList['B$currrentRowNumber'].value = TextCellValue(
        amIn.isNotEmpty ? amIn : '00:00 PM',
      );
      cellList['B$currrentRowNumber'].cellStyle = borderedCellStyle;

      cellList['C$currrentRowNumber'] = sheet.cell(
        CellIndex.indexByString('C$currrentRowNumber'),
      );
      cellList['C$currrentRowNumber'].value = TextCellValue(
        amOut.isNotEmpty ? amOut : '00:00 PM',
      );
      cellList['C$currrentRowNumber'].cellStyle = borderedCellStyle;

      cellList['D$currrentRowNumber'] = sheet.cell(
        CellIndex.indexByString('D$currrentRowNumber'),
      );
      cellList['D$currrentRowNumber'].value = TextCellValue(
        pmIn.isNotEmpty ? pmIn : '00:00 PM',
      );
      cellList['D$currrentRowNumber'].cellStyle = borderedCellStyle;

      cellList['E$currrentRowNumber'] = sheet.cell(
        CellIndex.indexByString('E$currrentRowNumber'),
      );
      cellList['E$currrentRowNumber'].value = TextCellValue(
        pmOut.isNotEmpty ? pmOut : '00:00 PM',
      );
      cellList['E$currrentRowNumber'].cellStyle = borderedCellStyle;

      // Placeholder for late/undertime (you can compute here)
      for (var col in ['F', 'G']) {
        cellList['$col$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('$col$currrentRowNumber'),
        );
        cellList['$col$currrentRowNumber'].value = null;
        cellList['$col$currrentRowNumber'].cellStyle = borderedCellStyle;
      }

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
        cellList['$col$currrentRowNumber'].value = TextCellValue(
          val.isNotEmpty ? val : '00:00 PM',
        );
        cellList['$col$currrentRowNumber'].cellStyle = borderedCellStyle;
      });

      for (var col in ['N', 'O']) {
        cellList['$col$currrentRowNumber'] = sheet.cell(
          CellIndex.indexByString('$col$currrentRowNumber'),
        );
        cellList['$col$currrentRowNumber'].value = null;
        cellList['$col$currrentRowNumber'].cellStyle = borderedCellStyle;
      }
    }

    startingDay++;
    startingRowNumber++;
  }

  // Total

  sheet.merge(
    CellIndex.indexByString('A$startingRowNumber'),
    CellIndex.indexByString('E$startingRowNumber'),
    customValue: TextCellValue(totalText),
  );

  cellList['A$startingRowNumber'] = sheet.cell(
    CellIndex.indexByString('A$startingRowNumber'),
  );
  cellList['A$startingRowNumber'].cellStyle = totalCellStyle;

  cellList['B$startingRowNumber'] = sheet.cell(
    CellIndex.indexByString('B$startingRowNumber'),
  );
  cellList['B$startingRowNumber'].cellStyle = borderedCellStyle;

  cellList['C$startingRowNumber'] = sheet.cell(
    CellIndex.indexByString('C$startingRowNumber'),
  );
  cellList['C$startingRowNumber'].cellStyle = topBottomBorderCellStyle;

  cellList['D$startingRowNumber'] = sheet.cell(
    CellIndex.indexByString('D$startingRowNumber'),
  );
  cellList['D$startingRowNumber'].cellStyle = topBottomBorderCellStyle;

  cellList['E$startingRowNumber'] = sheet.cell(
    CellIndex.indexByString('E$startingRowNumber'),
  );
  cellList['E$startingRowNumber'].cellStyle = topBottomBorderCellStyle;

  cellList['F$startingRowNumber'] = sheet.cell(
    CellIndex.indexByString('F$startingRowNumber'),
  );
  cellList['F$startingRowNumber'].cellStyle = borderedCellStyle;

  cellList['G$startingRowNumber'] = sheet.cell(
    CellIndex.indexByString('G$startingRowNumber'),
  );
  cellList['G$startingRowNumber'].cellStyle = borderedCellStyle;

  sheet.merge(
    CellIndex.indexByString('I$startingRowNumber'),
    CellIndex.indexByString('M$startingRowNumber'),
    customValue: TextCellValue(totalText),
  );
  cellList['I$startingRowNumber'] = sheet.cell(
    CellIndex.indexByString('I$startingRowNumber'),
  );
  cellList['I$startingRowNumber'].cellStyle = totalCellStyle;

  cellList['J$startingRowNumber'] = sheet.cell(
    CellIndex.indexByString('J$startingRowNumber'),
  );
  cellList['J$startingRowNumber'].cellStyle = topBottomBorderCellStyle;

  cellList['K$startingRowNumber'] = sheet.cell(
    CellIndex.indexByString('K$startingRowNumber'),
  );
  cellList['K$startingRowNumber'].cellStyle = topBottomBorderCellStyle;

  cellList['L$startingRowNumber'] = sheet.cell(
    CellIndex.indexByString('L$startingRowNumber'),
  );
  cellList['L$startingRowNumber'].cellStyle = topBottomBorderCellStyle;

  cellList['M$startingRowNumber'] = sheet.cell(
    CellIndex.indexByString('M$startingRowNumber'),
  );
  cellList['M$startingRowNumber'].cellStyle = borderedCellStyle;

  cellList['N$startingRowNumber'] = sheet.cell(
    CellIndex.indexByString('N$startingRowNumber'),
  );
  cellList['N$startingRowNumber'].cellStyle = borderedCellStyle;

  cellList['O$startingRowNumber'] = sheet.cell(
    CellIndex.indexByString('O$startingRowNumber'),
  );
  cellList['O$startingRowNumber'].cellStyle = borderedCellStyle;

  // Certification

  var certificationStartNumber = startingRowNumber + 2;
  var certificationEndNumber = startingRowNumber + 4;
  var attestationRowNumber = certificationEndNumber + 4;

  sheet.merge(
    CellIndex.indexByString('A$certificationStartNumber'),
    CellIndex.indexByString('G$certificationEndNumber'),
    customValue: TextCellValue(certificationText),
  );

  cellList['A$certificationStartNumber'] = sheet.cell(
    CellIndex.indexByString('A$certificationStartNumber'),
  );
  cellList['A$certificationStartNumber'].cellStyle = centerWrappedTextStyle;

  sheet.merge(
    CellIndex.indexByString('I$certificationStartNumber'),
    CellIndex.indexByString('O$certificationEndNumber'),
    customValue: TextCellValue(certificationText),
  );

  cellList['I$certificationStartNumber'] = sheet.cell(
    CellIndex.indexByString('I$certificationStartNumber'),
  );
  cellList['I$certificationStartNumber'].cellStyle = centerWrappedTextStyle;

  sheet.merge(
    CellIndex.indexByString('D$attestationRowNumber'),
    CellIndex.indexByString('G$attestationRowNumber'),
    customValue: TextCellValue(employeeText),
  );

  cellList['D$attestationRowNumber'] = sheet.cell(
    CellIndex.indexByString('D$attestationRowNumber'),
  );
  cellList['D$attestationRowNumber'].cellStyle = leftAlignedStyle;

  sheet.merge(
    CellIndex.indexByString('D$attestationRowNumber'),
    CellIndex.indexByString('G$attestationRowNumber'),
    customValue: TextCellValue(employeeText),
  );

  cellList['D$attestationRowNumber'] = sheet.cell(
    CellIndex.indexByString('D$attestationRowNumber'),
  );
  cellList['D$attestationRowNumber'].cellStyle = leftAlignedStyle;

  sheet.merge(
    CellIndex.indexByString('L$attestationRowNumber'),
    CellIndex.indexByString('O$attestationRowNumber'),
    customValue: TextCellValue(employeeText),
  );

  cellList['L$attestationRowNumber'] = sheet.cell(
    CellIndex.indexByString('L$attestationRowNumber'),
  );
  cellList['L$attestationRowNumber'].cellStyle = leftAlignedStyle;

  attestationRowNumber += 4;

  sheet.merge(
    CellIndex.indexByString('D$attestationRowNumber'),
    CellIndex.indexByString('G$attestationRowNumber'),
    customValue: TextCellValue(fullName),
  );

  cellList['D$attestationRowNumber'] = sheet.cell(
    CellIndex.indexByString('D$attestationRowNumber'),
  );
  cellList['D$attestationRowNumber'].cellStyle = leftBoldUnderlinedAlignedStyle;

  cellList['E$attestationRowNumber'] = sheet.cell(
    CellIndex.indexByString('E$attestationRowNumber'),
  );
  cellList['E$attestationRowNumber'].cellStyle = leftBoldUnderlinedAlignedStyle;

  cellList['F$attestationRowNumber'] = sheet.cell(
    CellIndex.indexByString('F$attestationRowNumber'),
  );
  cellList['F$attestationRowNumber'].cellStyle = leftBoldUnderlinedAlignedStyle;

  sheet.merge(
    CellIndex.indexByString('L$attestationRowNumber'),
    CellIndex.indexByString('O$attestationRowNumber'),
    customValue: TextCellValue(fullName),
  );

  cellList['L$attestationRowNumber'] = sheet.cell(
    CellIndex.indexByString('L$attestationRowNumber'),
  );
  cellList['L$attestationRowNumber'].cellStyle = leftBoldUnderlinedAlignedStyle;

  cellList['M$attestationRowNumber'] = sheet.cell(
    CellIndex.indexByString('M$attestationRowNumber'),
  );
  cellList['M$attestationRowNumber'].cellStyle = leftBoldUnderlinedAlignedStyle;

  cellList['N$attestationRowNumber'] = sheet.cell(
    CellIndex.indexByString('N$attestationRowNumber'),
  );
  cellList['N$attestationRowNumber'].cellStyle = leftBoldUnderlinedAlignedStyle;

  attestationRowNumber += 1;

  sheet.merge(
    CellIndex.indexByString('D$attestationRowNumber'),
    CellIndex.indexByString('G$attestationRowNumber'),
    customValue: TextCellValue(position),
  );

  cellList['D$attestationRowNumber'] = sheet.cell(
    CellIndex.indexByString('D$attestationRowNumber'),
  );
  cellList['D$attestationRowNumber'].cellStyle = leftAlignedStyle;

  sheet.merge(
    CellIndex.indexByString('L$attestationRowNumber'),
    CellIndex.indexByString('O$attestationRowNumber'),
    customValue: TextCellValue(position),
  );

  cellList['L$attestationRowNumber'] = sheet.cell(
    CellIndex.indexByString('L$attestationRowNumber'),
  );
  cellList['L$attestationRowNumber'].cellStyle = leftAlignedStyle;

  attestationRowNumber += 4;

  sheet.merge(
    CellIndex.indexByString('D$attestationRowNumber'),
    CellIndex.indexByString('G$attestationRowNumber'),
    customValue: TextCellValue(supervisorText),
  );

  cellList['D$attestationRowNumber'] = sheet.cell(
    CellIndex.indexByString('D$attestationRowNumber'),
  );
  cellList['D$attestationRowNumber'].cellStyle = leftAlignedStyle;

  sheet.merge(
    CellIndex.indexByString('L$attestationRowNumber'),
    CellIndex.indexByString('O$attestationRowNumber'),
    customValue: TextCellValue(supervisorText),
  );

  cellList['L$attestationRowNumber'] = sheet.cell(
    CellIndex.indexByString('L$attestationRowNumber'),
  );
  cellList['L$attestationRowNumber'].cellStyle = leftAlignedStyle;

  attestationRowNumber += 4;

  sheet.merge(
    CellIndex.indexByString('D$attestationRowNumber'),
    CellIndex.indexByString('G$attestationRowNumber'),
    customValue: TextCellValue(supervisor),
  );

  cellList['D$attestationRowNumber'] = sheet.cell(
    CellIndex.indexByString('D$attestationRowNumber'),
  );
  cellList['D$attestationRowNumber'].cellStyle = leftBoldUnderlinedAlignedStyle;

  cellList['E$attestationRowNumber'] = sheet.cell(
    CellIndex.indexByString('E$attestationRowNumber'),
  );
  cellList['E$attestationRowNumber'].cellStyle = leftBoldUnderlinedAlignedStyle;

  cellList['F$attestationRowNumber'] = sheet.cell(
    CellIndex.indexByString('F$attestationRowNumber'),
  );
  cellList['F$attestationRowNumber'].cellStyle = leftBoldUnderlinedAlignedStyle;

  sheet.merge(
    CellIndex.indexByString('L$attestationRowNumber'),
    CellIndex.indexByString('O$attestationRowNumber'),
    customValue: TextCellValue(supervisor),
  );

  cellList['L$attestationRowNumber'] = sheet.cell(
    CellIndex.indexByString('L$attestationRowNumber'),
  );
  cellList['L$attestationRowNumber'].cellStyle = leftBoldUnderlinedAlignedStyle;

  cellList['M$attestationRowNumber'] = sheet.cell(
    CellIndex.indexByString('M$attestationRowNumber'),
  );
  cellList['M$attestationRowNumber'].cellStyle = leftBoldUnderlinedAlignedStyle;

  cellList['N$attestationRowNumber'] = sheet.cell(
    CellIndex.indexByString('N$attestationRowNumber'),
  );
  cellList['N$attestationRowNumber'].cellStyle = leftBoldUnderlinedAlignedStyle;

  attestationRowNumber += 1;

  sheet.merge(
    CellIndex.indexByString('D$attestationRowNumber'),
    CellIndex.indexByString('G$attestationRowNumber'),
    customValue: TextCellValue(supervisorDesignation),
  );

  cellList['D$attestationRowNumber'] = sheet.cell(
    CellIndex.indexByString('D$attestationRowNumber'),
  );
  cellList['D$attestationRowNumber'].cellStyle = leftAlignedStyle;

  sheet.merge(
    CellIndex.indexByString('L$attestationRowNumber'),
    CellIndex.indexByString('O$attestationRowNumber'),
    customValue: TextCellValue(supervisorDesignation),
  );

  cellList['L$attestationRowNumber'] = sheet.cell(
    CellIndex.indexByString('L$attestationRowNumber'),
  );
  cellList['L$attestationRowNumber'].cellStyle = leftAlignedStyle;

  attestationRowNumber += 2;

  final Map<String, dynamic> dividerCells = {};

  for (var divider = 1; divider <= attestationRowNumber; divider++) {
    dividerCells['H$divider'] = sheet.cell(
      CellIndex.indexByString('H$divider'),
    );
    dividerCells['H$divider'].value = TextCellValue(dividerText);
    dividerCells['H$divider'].cellStyle = defaultCellStyle;
  }

  sheet.setColumnWidth(0, 6.0);
  sheet.setColumnWidth(1, 10);
  sheet.setColumnWidth(2, 10);
  sheet.setColumnWidth(3, 10);
  sheet.setColumnWidth(4, 10);
  sheet.setColumnWidth(5, 10);
  sheet.setColumnWidth(6, 10);
  sheet.setColumnWidth(7, 6.0);
  sheet.setColumnWidth(8, 6.0);
  sheet.setColumnWidth(9, 10);
  sheet.setColumnWidth(10, 10);
  sheet.setColumnWidth(11, 10);
  sheet.setColumnWidth(12, 10);
  sheet.setColumnWidth(13, 10);
  sheet.setColumnWidth(14, 10);

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

Map<String, String> extractLogTimes(List<AttendanceModel> dayLogs) {
  dayLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

  String formatTime(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }

  if (dayLogs.isEmpty) {
    return {'amIn': '', 'amOut': '', 'pmIn': '', 'pmOut': ''};
  }

  if (dayLogs.length == 1) {
    return {
      'amIn': formatTime(dayLogs[0].timestamp),
      'amOut': '',
      'pmIn': '',
      'pmOut': '',
    };
  }

  if (dayLogs.length == 2 || dayLogs.length == 3) {
    return {
      'amIn': formatTime(dayLogs.first.timestamp),
      'amOut': '',
      'pmIn': '',
      'pmOut': formatTime(dayLogs.last.timestamp),
    };
  }

  if (dayLogs.length == 4) {
    return {
      'amIn': formatTime(dayLogs[0].timestamp),
      'amOut': formatTime(dayLogs[1].timestamp),
      'pmIn': formatTime(dayLogs[2].timestamp),
      'pmOut': formatTime(dayLogs[3].timestamp),
    };
  }

  return {
    'amIn': formatTime(dayLogs[0].timestamp),
    'amOut': formatTime(dayLogs[1].timestamp),
    'pmIn': formatTime(dayLogs[2].timestamp),
    'pmOut': formatTime(dayLogs.last.timestamp),
  };
}

Future<String?> getPlatformDownloadPath() async {
  try {
    if (Platform.isAndroid) {
      Directory directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        directory = await getExternalStorageDirectory() ?? directory;
      }
      return directory.path;
    }

    if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    }

    if (Platform.isMacOS || Platform.isLinux) {
      return '${Platform.environment['HOME']}/Downloads';
    }

    if (Platform.isWindows) {
      return '${Platform.environment['USERPROFILE']}\\Downloads';
    }
  } catch (e) {
    rethrow;
  }

  return null;
}
