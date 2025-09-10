import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/attendance_model.dart';
import 'package:racconnect/logic/cubit/attendance_cubit.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';
import 'package:racconnect/logic/cubit/holiday_cubit.dart';
import 'package:racconnect/logic/cubit/leave_cubit.dart';
import 'package:racconnect/presentation/widgets/export_button.dart';
import 'package:racconnect/presentation/widgets/import_button.dart';
import 'package:racconnect/presentation/widgets/export_accomplishments_button.dart';
import 'package:racconnect/data/models/suspension_model.dart';
import 'package:racconnect/logic/cubit/suspension_cubit.dart';
import 'package:racconnect/utility/group_attendance.dart';
import 'package:racconnect/presentation/widgets/attendance_row.dart';
import 'package:racconnect/data/repositories/accomplishment_repository.dart';
import 'package:racconnect/logic/cubit/travel_cubit.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

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
  List<AttendanceModel> logs = [];
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  late AnimationController _greenGlowController;
  late Animation<Color?> _greenGlowAnimation;
  bool _isLoading = false; // Add loading state

  List<int> getYears() => List.generate(1, (i) => DateTime.now().year - i);
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

    context.read<HolidayCubit>().getAllHolidays();
    context.read<SuspensionCubit>().getAllSuspensions();

    // Load leaves
    final leaveCubit = context.read<LeaveCubit>();

    final authState = context.read<AuthCubit>().state;
    if (authState is AuthenticatedState) {
      final employeeNumber = authState.user.profile?.employeeNumber ?? '';
      if (employeeNumber.isNotEmpty) {
        await leaveCubit.getAllLeaves();

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
            .getEmployeeAccomplishments(employeeNumber, startDate, endDate);

        // Check if widget is still mounted
        if (!mounted) return;

        final state = cubit.state;
        if (state is GetEmployeeAttendanceSuccess) {
          final allLogs = state.attendanceModels;

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
              attendanceMap = groupAttendance(filteredLogs, suspensionMap);

              // Create a set of accomplishment dates for quick lookup
              accomplishmentDates = {
                for (var a in accomplishments)
                  DateFormat('yyyy-MM-dd').format(a.date),
              };
              _isLoading = false; // Set loading to false when data is loaded
            });
          }
        } else {
          // Handle other states (error, etc.)
          if (mounted) {
            setState(() {
              _isLoading = false;
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
        await travelCubit.getAllTravels();
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
  }

  void _onDateFilterChanged({int? year, int? month}) {
    setState(() {
      if (year != null) selectedYear = year;
      if (month != null) selectedMonth = month;
    });
    _loadInitialData();
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
            .getEmployeeAccomplishments(employeeNumber, startDate, endDate);

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
                for (var s in suspensionState.suspensionModels)
                  DateTime(s.datetime.year, s.datetime.month, s.datetime.day):
                      s,
              };
            }
            return Stack(
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
                            title: Text(
                              'Attendance',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Text(
                              'Click on work to add your daily accomplishment',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                            trailing: BlocBuilder<AuthCubit, AuthState>(
                              builder: (context, authState) {
                                final hasRole = _hasUserRole(authState);

                                if (!hasRole) {
                                  return const SizedBox.shrink();
                                }

                                return ExportButton(
                                  selectedYear: selectedYear,
                                  selectedMonth: selectedMonth,
                                  holidayMap: holidayMap,
                                  suspensionMap: suspensionMap,
                                  leaveMap: leaveMap,
                                  travelMap: travelMap,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<int>(
                                        initialValue: selectedYear,
                                        isExpanded: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Year',
                                        ),
                                        items:
                                            getYears().map((y) {
                                              return DropdownMenuItem(
                                                value: y,
                                                child: Text('$y'),
                                              );
                                            }).toList(),
                                        onChanged:
                                            (val) =>
                                                _onDateFilterChanged(year: val),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: DropdownButtonFormField<int>(
                                        isExpanded: true,
                                        initialValue: selectedMonth,
                                        decoration: const InputDecoration(
                                          labelText: 'Month',
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
                                            (val) => _onDateFilterChanged(
                                              month: val,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
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
                                          leaveMap: leaveMap, // Add leaveMap
                                          travelMap:
                                              travelMap, // Add travelMap
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

                    if (!hasRole) {
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

                    return Stack(
                      children: [
                        ExportAccomplishmentsButton(
                          selectedYear: selectedYear,
                          selectedMonth: selectedMonth,
                          holidayMap: holidayMap,
                          suspensionMap: suspensionMap,
                          leaveMap: leaveMap,
                          travelMap: travelMap,
                        ),
                        if (showImportButton)
                          ImportButton(
                            selectedYear: selectedYear,
                            selectedMonth: selectedMonth,
                            onRefresh: _loadInitialData,
                          ),
                      ],
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
