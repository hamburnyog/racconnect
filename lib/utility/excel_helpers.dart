import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import 'constants.dart';

Map<String, String> extractLogTimes(List<dynamic> dayLogs) {
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

  if (dayLogs.length == 2) {
    return {
      'amIn': formatTime(dayLogs.first.timestamp),
      'amOut': '',
      'pmIn': '',
      'pmOut': formatTime(dayLogs.last.timestamp),
    };
  }

  if (dayLogs.length == 3) {
    // For 3 logs: amIn, lunchOut, pmOut - if no lunch in is recorded, 
    // set the lunch out time as both amOut and pmIn
    return {
      'amIn': formatTime(dayLogs[0].timestamp),
      'amOut': formatTime(dayLogs[1].timestamp),  // lunch out
      'pmIn': formatTime(dayLogs[1].timestamp),   // lunch out becomes lunch in (automatically set)
      'pmOut': formatTime(dayLogs[2].timestamp),
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

void buildHeaderSection(Sheet sheet, String fullName, String monthYearText) {
  // CSC Text
  var cell1 = sheet.cell(CellIndex.indexByString('A2'));
  cell1.value = TextCellValue(cscText);
  cell1.cellStyle = cscCellStyle;
  var cell2 = sheet.cell(CellIndex.indexByString('I2'));
  cell2.value = TextCellValue(cscText);
  cell2.cellStyle = cscCellStyle;

  // NACC Text
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

  // DTR Text
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

  // Employee Name
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

  // Month Year Text
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

  // Table Headers
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
}

void buildTotalRowSection(
  Sheet sheet,
  int startingRowNumber,
  int totalLateUndertimeHours,
  int totalLateUndertimeMinutes,
  Map<String, dynamic> cellList,
) {
  // Total late/undertime for the month (blank if 0)
  cellList['F$startingRowNumber'] = sheet.cell(
    CellIndex.indexByString('F$startingRowNumber'),
  );
  cellList['F$startingRowNumber'].value =
      totalLateUndertimeHours > 0
          ? TextCellValue(totalLateUndertimeHours.toString())
          : TextCellValue('');
  cellList['F$startingRowNumber'].cellStyle = borderedCellStyle;

  cellList['G$startingRowNumber'] = sheet.cell(
    CellIndex.indexByString('G$startingRowNumber'),
  );
  cellList['G$startingRowNumber'].value =
      totalLateUndertimeMinutes > 0
          ? TextCellValue(totalLateUndertimeMinutes.toString())
          : TextCellValue('');
  cellList['G$startingRowNumber'].cellStyle = borderedCellStyle;

  cellList['N$startingRowNumber'] = sheet.cell(
    CellIndex.indexByString('N$startingRowNumber'),
  );
  cellList['N$startingRowNumber'].value =
      totalLateUndertimeHours > 0
          ? TextCellValue(totalLateUndertimeHours.toString())
          : TextCellValue('');
  cellList['N$startingRowNumber'].cellStyle = borderedCellStyle;

  cellList['O$startingRowNumber'] = sheet.cell(
    CellIndex.indexByString('O$startingRowNumber'),
  );
  cellList['O$startingRowNumber'].value =
      totalLateUndertimeMinutes > 0
          ? TextCellValue(totalLateUndertimeMinutes.toString())
          : TextCellValue('');
  cellList['O$startingRowNumber'].cellStyle = borderedCellStyle;

  // Total row (remaining cells)
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
}

void buildCertificationSection(
  Sheet sheet,
  int startingRowNumber,
  String fullName,
  String position,
  String supervisor,
  String supervisorDesignation,
  Map<String, dynamic> cellList,
  String? sectionCode,
) {
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

  final supervisorSections = ['OIC', 'AFU', 'PDU', 'LU'];

  sheet.merge(
    CellIndex.indexByString('D$attestationRowNumber'),
    CellIndex.indexByString('G$attestationRowNumber'),
    customValue: TextCellValue(
      supervisorSections.contains(sectionCode) ? supervisorText : '',
    ),
  );

  cellList['D$attestationRowNumber'] = sheet.cell(
    CellIndex.indexByString('D$attestationRowNumber'),
  );
  cellList['D$attestationRowNumber'].cellStyle = leftAlignedStyle;

  sheet.merge(
    CellIndex.indexByString('L$attestationRowNumber'),
    CellIndex.indexByString('O$attestationRowNumber'),
    customValue: TextCellValue(
      supervisorSections.contains(sectionCode) ? supervisorText : '',
    ),
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
  cellList['D$attestationRowNumber'].cellStyle =
      supervisorSections.contains('OIC')
          ? leftAlignedStyleOic
          : leftAlignedStyle;

  sheet.merge(
    CellIndex.indexByString('L$attestationRowNumber'),
    CellIndex.indexByString('O$attestationRowNumber'),
    customValue: TextCellValue(supervisorDesignation),
  );

  cellList['L$attestationRowNumber'] = sheet.cell(
    CellIndex.indexByString('L$attestationRowNumber'),
  );
  cellList['L$attestationRowNumber'].cellStyle =
      supervisorSections.contains('OIC')
          ? leftAlignedStyleOic
          : leftAlignedStyle;

  attestationRowNumber += 2;

  final Map<String, dynamic> dividerCells = {};

  for (var divider = 1; divider <= attestationRowNumber; divider++) {
    dividerCells['H$divider'] = sheet.cell(
      CellIndex.indexByString('H$divider'),
    );
    dividerCells['H$divider'].value = TextCellValue(dividerText);
    dividerCells['H$divider'].cellStyle = defaultCellStyle;
  }
}

void applyColumnWidths(Sheet sheet) {
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
}
