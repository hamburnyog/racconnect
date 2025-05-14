import 'package:flutter/material.dart';

const serverUrl = 'https://racconnect.codecarpentry.com';

enum ConnectionType { wifi, ethernet, mobile }

const sideBarItemsDev = [
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
];

const sideBarItemsOic = [
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
];

const sideBarItemsHr = [
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
    icon: Icon(Icons.calendar_month_outlined),
    activeIcon: Icon(Icons.calendar_month),
    label: 'Special Orders',
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
];
