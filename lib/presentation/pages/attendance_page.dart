import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/attendance_model.dart';
import 'package:racconnect/logic/cubit/attendance_cubit.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';
import 'package:racconnect/logic/cubit/holiday_cubit.dart';
import 'package:racconnect/utility/dtr_excel.dart';
import 'package:racconnect/utility/group_attendance.dart';
import 'package:share_plus/share_plus.dart';

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
        return Padding(
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
                  trailing:
                      isSmallScreen
                          ? IconButton(
                            onPressed: () async {
                              final profile =
                                  (context.read<AuthCubit>().state
                                          as AuthSignedIn)
                                      .user
                                      .profile!;
                              final employeeNumber = profile.employeeNumber;
                              final selectedDate = DateTime(
                                selectedYear,
                                selectedMonth,
                              );

                              final monthlyLogs = await context
                                  .read<AttendanceCubit>()
                                  .attendanceRepository
                                  .getEmployeeAttendanceForMonth(
                                    employeeNumber,
                                    selectedDate,
                                  );

                              final filePath = await generateExcel(
                                selectedDate,
                                profile,
                                monthlyLogs,
                              );

                              if (context.mounted && filePath != null) {
                                final file = XFile(filePath);
                                final box =
                                    context.findRenderObject() as RenderBox?;

                                final result = await SharePlus.instance.share(
                                  ShareParams(
                                    text: '📄 Generated DTR Excel file',
                                    files: [file],
                                    sharePositionOrigin:
                                        box!.localToGlobal(Offset.zero) &
                                        box.size,
                                  ),
                                );

                                if (!context.mounted) {
                                  return;
                                }

                                if (result.status ==
                                    ShareResultStatus.success) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        '✅ File shared successfully!',
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'ℹ️ Share canceled or failed',
                                      ),
                                    ),
                                  );
                                }
                              } else if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '❌ Failed to generate Excel file',
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.file_download,
                              color: Colors.white,
                            ),
                          )
                          : ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: 150,
                              maxHeight: 40,
                            ),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.download),
                              label: const Text('Export'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Theme.of(context).primaryColor,
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              onPressed: () async {
                                final profile =
                                    (context.read<AuthCubit>().state
                                            as AuthSignedIn)
                                        .user
                                        .profile!;
                                final employeeNumber = profile.employeeNumber;
                                final selectedDate = DateTime(
                                  selectedYear,
                                  selectedMonth,
                                );

                                final monthlyLogs = await context
                                    .read<AttendanceCubit>()
                                    .attendanceRepository
                                    .getEmployeeAttendanceForMonth(
                                      employeeNumber,
                                      selectedDate,
                                    );

                                final filePath = await generateExcel(
                                  selectedDate,
                                  profile,
                                  monthlyLogs,
                                );

                                if (context.mounted && filePath != null) {
                                  final file = XFile(filePath);
                                  final box =
                                      context.findRenderObject() as RenderBox?;

                                  final result = await SharePlus.instance.share(
                                    ShareParams(
                                      text: '📄 Generated DTR Excel file',
                                      files: [file],
                                      sharePositionOrigin:
                                          box!.localToGlobal(Offset.zero) &
                                          box.size,
                                    ),
                                  );

                                  if (!context.mounted) {
                                    return;
                                  }

                                  if (result.status ==
                                      ShareResultStatus.success) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          '✅ File shared successfully!',
                                        ),
                                      ),
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'ℹ️ Share canceled or failed',
                                        ),
                                      ),
                                    );
                                  }
                                } else if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        '❌ Failed to generate Excel file',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: selectedYear,
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
                                    (val) => _onDateFilterChanged(year: val),
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
                                    (val) => _onDateFilterChanged(month: val),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 10,
                          ),
                          child: Row(
                            children: const [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Date (Day)',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Text(
                                    'AM',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Center(
                                  child: Text(
                                    'PM',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ListView.builder(
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
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
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
            flex: 3,
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
            flex: 4,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
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
          flex: 3,
          child: Row(
            children: [
              Text(
                DateFormat('MMM dd (E)').format(day),
                style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
              ),
              SizedBox(width: 5),
              data?['type'] != null
                  ? _buildBadge(data!['type']!, smallScreen: isSmallScreen)
                  : const Text(''),
            ],
          ),
        ),
        Expanded(
          child: Text(
            data?['timeIn'] ?? '—',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
          ),
        ),
        Expanded(
          child: Text(
            data?['lunchOut'] ?? '—',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
          ),
        ),
        Expanded(
          child: Text(
            data?['lunchIn'] ?? '—',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
          ),
        ),
        Expanded(
          child: Text(
            data?['timeOut'] ?? '—',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
          ),
        ),
      ],
    ),
  );
}

Widget _buildBadge(String type, {bool smallScreen = false}) {
  final normalized = type.toLowerCase();
  final isWFH = normalized.contains('wfh');

  final color = isWFH ? Colors.purple : Colors.teal;

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(20),
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
