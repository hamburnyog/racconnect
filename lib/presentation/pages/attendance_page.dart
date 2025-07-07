import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/attendance_model.dart';
import 'package:racconnect/logic/cubit/attendance_cubit.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';
import 'package:racconnect/logic/cubit/holiday_cubit.dart';
import 'package:racconnect/presentation/widgets/export_button.dart';
import 'package:racconnect/presentation/widgets/import_button.dart';
import 'package:racconnect/utility/group_attendance.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  Map<String, Map<String, String>> attendanceMap = {};
  Map<DateTime, String> holidayMap = {};
  List<AttendanceModel> logs = [];
  final ScrollController _scrollController = ScrollController();

  List<int> getYears() => List.generate(1, (i) => DateTime.now().year - i);
  List<DateTime> getDaysInMonth(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0);
    return List.generate(lastDay.day, (i) => DateTime(year, month, i + 1));
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    context.read<HolidayCubit>().getAllHolidays();

    final authState = context.read<AuthCubit>().state;
    if (authState is AuthSignedIn) {
      final employeeNumber = authState.user.profile?.employeeNumber ?? '';
      if (employeeNumber.isNotEmpty) {
        final cubit = context.read<AttendanceCubit>();
        await cubit.getEmployeeAttendance(employeeNumber: employeeNumber);

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

          setState(() {
            attendanceMap = groupAttendance(filteredLogs);
          });
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
        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Column(
                children: [
                  Card(
                    color: Theme.of(context).primaryColor,
                    child: ListTile(
                      minTileHeight: 70,
                      leading: const Icon(
                        Icons.access_time_rounded,
                        color: Colors.white,
                      ),
                      title: Text(
                        isSmallScreen ? 'Attendance' : 'Attendance Records',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        isSmallScreen
                            ? 'Select a date to view records'
                            : 'Select a date to view attendance records',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: isSmallScreen ? 11 : 14,
                        ),
                      ),
                      trailing: ExportButton(
                        selectedYear: selectedYear,
                        selectedMonth: selectedMonth,
                        holidayMap: holidayMap,
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
                                    value: selectedYear,
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
                                    value: selectedMonth,
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
                                        (val) =>
                                            _onDateFilterChanged(month: val),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: Scrollbar(
                                controller: _scrollController,
                                thumbVisibility: true,
                                child: ListView.builder(
                                  controller: _scrollController,
                                  itemCount: days.length,
                                  itemBuilder: (context, index) {
                                    return buildAttendanceRow(
                                      day: days[index],
                                      attendanceMap: attendanceMap,
                                      holidayMap: holidayMap,
                                      isSmallScreen: isSmallScreen,
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
            ImportButton(
              selectedYear: selectedYear,
              selectedMonth: selectedMonth,
              onRefresh: _loadInitialData,
            ),
          ],
        );
      },
    );
  }
}

Widget buildAttendanceRow({
  required DateTime day,
  required Map<String, Map<String, String>> attendanceMap,
  required Map<DateTime, String> holidayMap,
  required bool isSmallScreen,
}) {
  final dateKey = DateFormat('yyyy-MM-dd').format(day);
  final data = attendanceMap[dateKey];
  final holidayName = holidayMap[DateTime(day.year, day.month, day.day)];
  final isWeekend =
      day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
  final isToday = DateUtils.isSameDay(day, DateTime.now());

  final rowColor =
      holidayName != null
          ? Colors.orange.shade50
          : isWeekend
          ? Colors.grey.shade200
          : isToday
          ? Colors.yellow.withValues(alpha: 0.1)
          : null;

  final label = holidayName ?? (isWeekend ? 'Weekend' : '');
  final isNonWorkingDay = holidayName != null || isWeekend;

  if (isNonWorkingDay) {
    return Container(
      color: rowColor,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              DateFormat('MMM dd (E)').format(day),
              style: TextStyle(
                fontSize: isSmallScreen ? 12 : 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isSmallScreen ? 12 : 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  return Container(
    color: rowColor,
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
    child: Row(
      children: [
        Expanded(
          child: Text(
            DateFormat('MMM dd (E)').format(day),
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              color: Colors.teal,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: buildTimeCell(data?['timeIn'], isSmallScreen: isSmallScreen),
        ),
        Expanded(
          child: buildTimeCell(data?['lunchOut'], isSmallScreen: isSmallScreen),
        ),
        Expanded(
          child: buildTimeCell(data?['lunchIn'], isSmallScreen: isSmallScreen),
        ),
        Expanded(
          child: buildTimeCell(data?['timeOut'], isSmallScreen: isSmallScreen),
        ),
        Expanded(
          child:
              data?['type'] != null
                  ? _buildBadge(data!['type']!, smallScreen: isSmallScreen)
                  : const SizedBox.shrink(),
        ),
      ],
    ),
  );
}

Widget buildTimeCell(String? timeString, {required bool isSmallScreen}) {
  if (timeString == null || timeString == '—') {
    return Text(
      '—',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
    );
  }

  final match = RegExp(r'^(\d{1,2}:\d{2})(AM|PM)$').firstMatch(timeString);
  if (match != null && isSmallScreen) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(match.group(1)!, style: const TextStyle(fontSize: 12)),
        Text(
          match.group(2)!,
          style: const TextStyle(fontSize: 10, height: 1.2),
        ),
      ],
    );
  }

  return Text(
    timeString,
    textAlign: TextAlign.center,
    style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
  );
}

Widget _buildBadge(String type, {bool smallScreen = false}) {
  final normalized = type.toLowerCase();
  final isWFH = normalized.contains('wfh');

  final color = isWFH ? Colors.purple : Colors.teal;

  return Container(
    margin: EdgeInsets.only(left: 5),
    padding: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Center(
      child: Text(
        isWFH ? 'WFH' : 'BIO',
        style: TextStyle(
          fontSize: smallScreen ? 8 : 14,
          fontWeight: FontWeight.w600,
          color: color.shade400,
        ),
      ),
    ),
  );
}
