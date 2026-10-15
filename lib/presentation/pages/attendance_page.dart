import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/blocs/cubit/attendance_cubit.dart';
import 'package:racconnect/data/blocs/cubit/auth_cubit.dart';
import 'package:racconnect/data/blocs/cubit/holiday_cubit.dart';
import 'package:racconnect/data/blocs/cubit/leave_cubit.dart';
import 'package:racconnect/presentation/widgets/export_button.dart';
import 'package:racconnect/presentation/widgets/import_button.dart';
import 'package:racconnect/presentation/widgets/clock_in_button.dart';
import 'package:racconnect/presentation/widgets/attendance_form.dart';
import 'package:racconnect/presentation/widgets/export_accomplishments_button.dart';
import 'package:racconnect/data/models/suspension_model.dart';
import 'package:racconnect/data/blocs/cubit/suspension_cubit.dart';
import 'package:racconnect/utility/group_attendance.dart';
import 'package:racconnect/presentation/widgets/attendance_row.dart';
import 'package:racconnect/data/repositories/accomplishment_repository.dart';
import 'package:racconnect/data/blocs/cubit/travel_cubit.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AttendancePage extends StatefulWidget {
  final VoidCallback? onNavigateToProfile;

  const AttendancePage({super.key, this.onNavigateToProfile});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage>
    with TickerProviderStateMixin {
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  Map<String, Map<String, String>> attendanceMap = {};
  Map<DateTime, String> holidayMap = {};
  Map<DateTime, SuspensionModel> suspensionMap = {};
  Map<DateTime, String> leaveMap = {}; // For storing leave information
  Map<DateTime, String> travelMap = {}; // For storing travel order information
  Set<String> accomplishmentDates = {};
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  late AnimationController _greenGlowController;
  late Animation<Color?> _greenGlowAnimation;
  bool _isLoading = false; // Add loading state
  bool _lockClockIn = true;
  int _timeLogsToday = 0;

  List<int> getYears() => List.generate(2, (i) => DateTime.now().year - i);
  List<DateTime> getDaysInMonth(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0);
    return List.generate(lastDay.day, (i) => DateTime(year, month, i + 1));
  }

  @override
  void initState() {
    super.initState();
    _greenGlowController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
    _greenGlowAnimation = ColorTween(
      begin: Colors.lightGreen.withValues(alpha: 0.1),
      end: Colors.lightGreen.withValues(alpha: 0.3),
    ).animate(_greenGlowController);

    _loadInitialData();
  }

  /// Check if the user has a role assigned
  bool _hasUserRole(AuthState authState) {
    if (authState is! AuthenticatedState) {
      return false;
    }

    final role = authState.user.role;
    // Check if role is not null and not empty
    return role != null && role.isNotEmpty;
  }

  @override
  void dispose() {
    _greenGlowController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _checkProfile();

      context.read<HolidayCubit>().getAllHolidays(year: selectedYear);
      context.read<SuspensionCubit>().getAllSuspensions(year: selectedYear);

      // Load leaves
      final leaveCubit = context.read<LeaveCubit>();

      final authState = context.read<AuthCubit>().state;
      if (authState is AuthenticatedState) {
        final employeeNumber = authState.user.profile?.employeeNumber ?? '';
        if (employeeNumber.isNotEmpty) {
          await leaveCubit.getAllLeaves(year: selectedYear);

          // Check if widget is still mounted
          if (!mounted) return;

          final cubit = context.read<AttendanceCubit>();
          await cubit.getEmployeeAttendance(employeeNumber: employeeNumber);

          // Check if widget is still mounted
          if (!mounted) return;

          // Fetch accomplishments for the selected month
          final startDate = DateTime(selectedYear, selectedMonth, 1);
          final endDate = DateTime(
            selectedYear,
            selectedMonth + 1,
            1,
          ).subtract(const Duration(days: 1));
          final accomplishmentRepository = AccomplishmentRepository();
          final accomplishments = await accomplishmentRepository
              .getEmployeeAccomplishmentsForMonth(
                employeeNumber,
                startDate,
                endDate,
              );

          // Check if widget is still mounted
          if (!mounted) return;

          final state = cubit.state;
          if (state is GetEmployeeAttendanceSuccess) {
            final allLogs = state.attendanceModels;

            final today = DateTime.now();
            final todaysLogs =
                allLogs
                    .where(
                      (log) =>
                          log.timestamp.year == today.year &&
                          log.timestamp.month == today.month &&
                          log.timestamp.day == today.day,
                    )
                    .toList();

            final filteredLogs =
                allLogs
                    .where(
                      (log) =>
                          log.timestamp.year == selectedYear &&
                          log.timestamp.month == selectedMonth,
                    )
                    .toList();

            if (mounted) {
              setState(() {
                _timeLogsToday = todaysLogs.length;
                attendanceMap = groupAttendance(filteredLogs, suspensionMap);

                // Create a set of accomplishment dates for quick lookup
                accomplishmentDates = {
                  for (var a in accomplishments)
                    DateFormat('yyyy-MM-dd').format(a.date),
                };
              });
            }
          }

          // Handle leave state
          final leaveState = leaveCubit.state;
          if (leaveState is GetAllLeaveSuccess) {
            if (mounted) {
              setState(() {
                leaveMap = {};
                for (var leave in leaveState.leaveModels) {
                  if (leave.employeeNumbers.contains(employeeNumber)) {
                    for (var date in leave.specificDates) {
                      final dateKey = DateTime(date.year, date.month, date.day);
                      leaveMap[dateKey] = leave.type;
                    }
                  }
                }
              });
            }
          }

          // Handle travel state
          final travelCubit = context.read<TravelCubit>();
          await travelCubit.getAllTravels(year: selectedYear);
          final travelState = travelCubit.state;
          if (travelState is GetAllTravelSuccess) {
            if (mounted) {
              setState(() {
                travelMap = {};
                for (var travel in travelState.travelModels) {
                  // Only show travel orders for the current employee
                  if (travel.employeeNumbers.contains(employeeNumber)) {
                    // Add each date in the travel order
                    for (var date in travel.specificDates) {
                      final dateKey = DateTime(date.year, date.month, date.day);
                      travelMap[dateKey] = travel.soNumber;
                    }
                  }
                }
              });
            }
          }
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onDateFilterChanged({int? year, int? month}) {
    setState(() {
      if (year != null) selectedYear = year;
      if (month != null) selectedMonth = month;
    });
    _loadInitialData();
  }

  Future<void> _checkProfile() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthenticatedState) {
      var profile = authState.user.profile;
      var employeeNumber = profile?.employeeNumber ?? '';

      if (employeeNumber.isNotEmpty) {
        if (mounted) {
          setState(() {
            _lockClockIn = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _lockClockIn = true;
          });
        }
      }
    }
  }

  void _showAttendanceForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      scrollControlDisabledMaxHeightRatio: 0.75,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext builder) {
        return AttendanceForm();
      },
    ).then((_) => _loadInitialData());
  }

  Future<void> _refreshAccomplishments() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthenticatedState) {
      final employeeNumber = authState.user.profile?.employeeNumber ?? '';
      if (employeeNumber.isNotEmpty) {
        // Fetch accomplishments for the selected month
        final startDate = DateTime(selectedYear, selectedMonth, 1);
        final endDate = DateTime(
          selectedYear,
          selectedMonth + 1,
          1,
        ).subtract(const Duration(days: 1));
        final accomplishmentRepository = AccomplishmentRepository();
        final accomplishments = await accomplishmentRepository
            .getEmployeeAccomplishmentsForMonth(
              employeeNumber,
              startDate,
              endDate,
            );

        setState(() {
          // Update the accomplishment dates set
          accomplishmentDates = {
            for (var a in accomplishments)
              DateFormat('yyyy-MM-dd').format(a.date),
          };
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = getDaysInMonth(selectedYear, selectedMonth);
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    return BlocBuilder<HolidayCubit, HolidayState>(
      builder: (context, state) {
        if (state is GetAllHolidaySuccess) {
          holidayMap = {
            for (var h in state.holidayModels)
              DateTime(h.date.year, h.date.month, h.date.day): h.name,
          };
        }
        return BlocBuilder<SuspensionCubit, SuspensionState>(
          builder: (context, suspensionState) {
            if (suspensionState is GetAllSuspensionSuccess) {
              suspensionMap = {
                for (var s in suspensionState.filteredSuspensionModels)
                  DateTime(s.datetime.year, s.datetime.month, s.datetime.day):
                      s,
              };
            }
            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: Colors.transparent,
              body: Stack(
                key: _scaffoldMessengerKey,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    child: Column(
                      children: [
                        Skeletonizer(
                          enabled: _isLoading,
                          child: Card(
                            color: Theme.of(context).primaryColor,
                            child: ListTile(
                              minTileHeight: 70,
                              leading: const Icon(
                                Icons.access_time_rounded,
                                color: Colors.white,
                              ),
                              title: const Text(
                                'Attendance',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              subtitle: const Text(
                                'Click on any day to add your daily accomplishment',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                              trailing: ClockInButton(
                                lockClockIn: _lockClockIn,
                                onPressed: _showAttendanceForm,
                                timeLogsToday: _timeLogsToday,
                              ),
                            ),
                          ),
                        ),
                        if (_lockClockIn && !_isLoading)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0, top: 4.0),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                border: Border.all(color: Colors.orange.shade200, width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.shade100.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade100,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.person_off_rounded, color: Colors.orange.shade800, size: 24),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Text(
                                          'Profile Incomplete',
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'You need to complete your profile (including your Employee Number) before you can log time or generate attendance reports.',
                                    style: TextStyle(
                                      color: Colors.orange.shade900,
                                      fontSize: 13,
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange.shade600,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () {
                                        if (widget.onNavigateToProfile != null) {
                                          widget.onNavigateToProfile!();
                                        }
                                      },
                                      icon: const Icon(Icons.edit_document, size: 18),
                                      label: const Text(
                                        'Update Profile Now',
                                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8.0,
                            horizontal: 3.0,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<int>(
                                  isExpanded: true,
                                  initialValue: selectedMonth,
                                  decoration: InputDecoration(
                                    labelText: 'Month',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 12,
                                    ),
                                  ),
                                  items: List.generate(12, (i) {
                                    return DropdownMenuItem(
                                      value: i + 1,
                                      child: Text(
                                        DateFormat(
                                          'MMMM',
                                        ).format(DateTime(0, i + 1)),
                                      ),
                                    );
                                  }),
                                  onChanged:
                                      (val) => _onDateFilterChanged(month: val),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 1,
                                child: DropdownButtonFormField<int>(
                                  initialValue: selectedYear,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    labelText: 'Year',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[200],
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 12,
                                    ),
                                  ),
                                  items:
                                      getYears().map((y) {
                                        return DropdownMenuItem(
                                          value: y,
                                          child: Text('$y'),
                                        );
                                      }).toList(),
                                  onChanged:
                                      (val) => _onDateFilterChanged(year: val),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Skeletonizer(
                                      enabled: _isLoading,
                                      child: ListView.builder(
                                        controller: _scrollController,
                                        itemCount: days.length,
                                        itemBuilder: (context, index) {
                                          return buildAttendanceRow(
                                            context: context,
                                            scaffoldMessengerKey:
                                                _scaffoldMessengerKey,
                                            day: days[index],
                                            attendanceMap: attendanceMap,
                                            holidayMap: holidayMap,
                                            suspensionMap: suspensionMap,
                                            leaveMap: leaveMap,
                                            travelMap: travelMap,
                                            accomplishmentDates:
                                                accomplishmentDates,
                                            isSmallScreen: isSmallScreen,
                                            greenGlowAnimation:
                                                _greenGlowAnimation,
                                            onRefreshAccomplishments:
                                                _refreshAccomplishments,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, authState) {
                      // Only show export buttons for authenticated users with a role
                      final hasRole = _hasUserRole(authState);
                      final hasProfile =
                          authState is AuthenticatedState &&
                          (authState.user.profile?.employeeNumber ?? '')
                              .isNotEmpty;

                      if (!hasRole && !hasProfile) {
                        return const SizedBox.shrink();
                      }

                      // Check if user is Developer on desktop to show import button
                      final isDeveloper =
                          authState is AuthenticatedState &&
                          authState.user.role == 'Developer';
                      final isDesktop =
                          Platform.isWindows ||
                          Platform.isMacOS ||
                          Platform.isLinux;
                      final showImportButton = isDesktop && isDeveloper;

                      return Positioned(
                        right: 0,
                        bottom: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (showImportButton)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: ImportButton(
                                  selectedYear: selectedYear,
                                  selectedMonth: selectedMonth,
                                  onRefresh: _loadInitialData,
                                ),
                              ),
                            ExportAccomplishmentsButton(
                              selectedYear: selectedYear,
                              selectedMonth: selectedMonth,
                              holidayMap: holidayMap,
                              suspensionMap: suspensionMap,
                              leaveMap: leaveMap,
                              travelMap: travelMap,
                            ),
                            const SizedBox(height: 10),
                            ExportButton(
                              selectedYear: selectedYear,
                              selectedMonth: selectedMonth,
                              holidayMap: holidayMap,
                              suspensionMap: suspensionMap,
                              leaveMap: leaveMap,
                              travelMap: travelMap,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
