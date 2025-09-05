import 'package:excel/excel.dart';
import 'package:flutter/material.dart' hide Border, BorderStyle;

const String serverUrl = 'https://racconnect.codecarpentry.com';

const String totalText = 'TOTAL  ';
const String arrivalText = 'Arrival';
const String departureText = 'Departure';
const String hoursText = 'Hours';
const String minutesText = 'Minutes';
const String amText = 'A.M.';
const String pmText = 'P.M.';
const String lateUndertimeText = 'LATE / UNDERTIME';
const String daysText = 'DAYS';
const String cscText = 'CSC Form No. 48';
const String naccText = 'NATIONAL AUTHORITY FOR CHILD CARE';
const String dtrText = 'DAILY TIME RECORD';
const String certificationText =
    'I CERTIFY on my honor that the above is a true and correct report of the hours of work performed, record of which was made daily at the time of arrival and departure from office. ';
const String employeeNameText = '{EMPLOYEE NAME}';
const String employeePositionText = '{POSITION}';
const String supervisorNameText = '{SUPERVISORY NAME}';
const String supervisorDesignationText = '{DESIGNATION}';
const String employeeText = 'Employee:';
const String supervisorText = 'Immediate Supervisor:';
const String dividerText = ':';

enum ConnectionType { wifi, ethernet, mobile }

const sideBarItemsDev = [
  ...sideBarItemsUser,
  BottomNavigationBarItem(
    icon: Icon(Icons.person_outline_rounded),
    activeIcon: Icon(Icons.person_rounded),
    label: 'Personnel',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.group_outlined),
    activeIcon: Icon(Icons.group_rounded),
    label: 'Sections',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.calendar_month_outlined),
    activeIcon: Icon(Icons.calendar_month),
    label: 'Holidays',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.flood_outlined),
    activeIcon: Icon(Icons.flood),
    label: 'Suspensions',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.airplane_ticket_outlined),
    activeIcon: Icon(Icons.directions_car),
    label: 'Travels',
  ),
];

const sideBarItemsOic = [
  ...sideBarItemsUser,
  BottomNavigationBarItem(
    icon: Icon(Icons.person_outline_rounded),
    activeIcon: Icon(Icons.person_rounded),
    label: 'Personnel',
  ),
];

const sideBarItemsUnitHead = [
  ...sideBarItemsUser,
  BottomNavigationBarItem(
    icon: Icon(Icons.person_outline_rounded),
    activeIcon: Icon(Icons.person_rounded),
    label: 'Personnel',
  ),
];

const sideBarItemsHr = [
  ...sideBarItemsUser,
  BottomNavigationBarItem(
    icon: Icon(Icons.person_outline_rounded),
    activeIcon: Icon(Icons.person_rounded),
    label: 'Personnel',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.calendar_month_outlined),
    activeIcon: Icon(Icons.calendar_month),
    label: 'Holidays',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.calendar_month_outlined),
    activeIcon: Icon(Icons.calendar_month),
    label: 'Suspensions',
  ),
];

const sideBarItemsRecords = [
  ...sideBarItemsUser,
  BottomNavigationBarItem(
    icon: Icon(Icons.airplane_ticket_outlined),
    activeIcon: Icon(Icons.directions_car),
    label: 'Travels',
  ),
];

const sideBarItemsUser = [
  BottomNavigationBarItem(
    icon: Icon(Icons.home_outlined),
    activeIcon: Icon(Icons.home_rounded),
    label: 'Home',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.access_time),
    activeIcon: Icon(Icons.access_time_filled),
    label: 'Attendance',
  ),
  BottomNavigationBarItem(
    icon: Icon(Icons.sick_outlined),
    activeIcon: Icon(Icons.sick_rounded),
    label: 'Leaves',
  ),
];

// Cell Styles
CellStyle defaultCellStyle = CellStyle(
  fontSize: 10,
  fontFamily: getFontFamily(FontFamily.Arial),
  verticalAlign: VerticalAlign.Center,
  horizontalAlign: HorizontalAlign.Center,
);

CellStyle topBottomBorderCellStyle = CellStyle(
  fontSize: 10,
  fontFamily: getFontFamily(FontFamily.Arial),
  verticalAlign: VerticalAlign.Center,
  horizontalAlign: HorizontalAlign.Center,
  bottomBorder: Border(borderStyle: BorderStyle.Thin),
  topBorder: Border(borderStyle: BorderStyle.Thin),
);

CellStyle noBottomBorderCellStyle = CellStyle(
  fontSize: 10,
  fontFamily: getFontFamily(FontFamily.Arial),
  verticalAlign: VerticalAlign.Center,
  horizontalAlign: HorizontalAlign.Center,
  topBorder: Border(borderStyle: BorderStyle.Thin),
  leftBorder: Border(borderStyle: BorderStyle.Thin),
  rightBorder: Border(borderStyle: BorderStyle.Thin),
);

CellStyle noLeftBorderCellStyle = CellStyle(
  fontSize: 10,
  fontFamily: getFontFamily(FontFamily.Arial),
  verticalAlign: VerticalAlign.Center,
  horizontalAlign: HorizontalAlign.Center,
  topBorder: Border(borderStyle: BorderStyle.Thin),
  bottomBorder: Border(borderStyle: BorderStyle.Thin),
  rightBorder: Border(borderStyle: BorderStyle.Thin),
);

CellStyle noTopBorderCellStyle = CellStyle(
  fontSize: 10,
  fontFamily: getFontFamily(FontFamily.Arial),
  verticalAlign: VerticalAlign.Center,
  horizontalAlign: HorizontalAlign.Center,
  leftBorder: Border(borderStyle: BorderStyle.Thin),
  bottomBorder: Border(borderStyle: BorderStyle.Thin),
  rightBorder: Border(borderStyle: BorderStyle.Thin),
);

CellStyle borderedCellStyle = CellStyle(
  fontSize: 10,
  fontFamily: getFontFamily(FontFamily.Arial),
  verticalAlign: VerticalAlign.Center,
  horizontalAlign: HorizontalAlign.Center,
  topBorder: Border(borderStyle: BorderStyle.Thin),
  leftBorder: Border(borderStyle: BorderStyle.Thin),
  bottomBorder: Border(borderStyle: BorderStyle.Thin),
  rightBorder: Border(borderStyle: BorderStyle.Thin),
);

CellStyle totalCellStyle = CellStyle(
  bold: true,
  fontSize: 10,
  fontFamily: getFontFamily(FontFamily.Arial),
  verticalAlign: VerticalAlign.Center,
  horizontalAlign: HorizontalAlign.Right,
  topBorder: Border(borderStyle: BorderStyle.Thin),
  leftBorder: Border(borderStyle: BorderStyle.Thin),
  bottomBorder: Border(borderStyle: BorderStyle.Thin),
  rightBorder: Border(borderStyle: BorderStyle.Thin),
);

CellStyle centerTextStyle = CellStyle(
  fontSize: 10,
  fontFamily: getFontFamily(FontFamily.Arial),
  verticalAlign: VerticalAlign.Center,
  horizontalAlign: HorizontalAlign.Center,
);

CellStyle centerWrappedTextStyle = CellStyle(
  textWrapping: TextWrapping.WrapText,
  fontSize: 10,
  fontFamily: getFontFamily(FontFamily.Arial),
  verticalAlign: VerticalAlign.Center,
  horizontalAlign: HorizontalAlign.Center,
);

CellStyle boldCellStyle = CellStyle(
  bold: true,
  fontSize: 10,
  fontFamily: getFontFamily(FontFamily.Arial),
  verticalAlign: VerticalAlign.Center,
  horizontalAlign: HorizontalAlign.Center,
);

CellStyle cscCellStyle = CellStyle(
  fontSize: 8,
  fontFamily: getFontFamily(FontFamily.Arial),
);

CellStyle naccCellStyle = CellStyle(
  bold: true,
  fontSize: 12,
  fontFamily: getFontFamily(FontFamily.Arial),
  verticalAlign: VerticalAlign.Center,
  horizontalAlign: HorizontalAlign.Center,
);

CellStyle dtrCellStyle = CellStyle(
  fontSize: 11,
  fontFamily: getFontFamily(FontFamily.Arial),
  verticalAlign: VerticalAlign.Center,
  horizontalAlign: HorizontalAlign.Center,
);

CellStyle leftAlignedStyle = CellStyle(
  fontSize: 10,
  fontFamily: getFontFamily(FontFamily.Arial),
  verticalAlign: VerticalAlign.Center,
  horizontalAlign: HorizontalAlign.Left,
);

CellStyle leftBoldUnderlinedAlignedStyle = CellStyle(
  bold: true,
  fontSize: 10,
  fontFamily: getFontFamily(FontFamily.Arial),
  verticalAlign: VerticalAlign.Center,
  horizontalAlign: HorizontalAlign.Left,
  bottomBorder: Border(borderStyle: BorderStyle.Thin),
);
