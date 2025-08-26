import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/attendance_model.dart';
import 'package:racconnect/logic/cubit/attendance_cubit.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';
import 'package:racconnect/logic/cubit/holiday_cubit.dart';
import 'package:racconnect/presentation/widgets/export_button.dart';
import 'package:racconnect/presentation/widgets/import_button.dart';
import 'package:racconnect/data/models/suspension_model.dart';
import 'package:racconnect/logic/cubit/suspension_cubit.dart';
import 'package:racconnect/utility/group_attendance.dart';
import 'package:flutter/services.dart';

class AttendancePage extends StatefulWidget {
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage>
    with SingleTickerProviderStateMixin {
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  Map<String, Map<String, String>> attendanceMap = {};
  Map<DateTime, String> holidayMap = {};
  Map<DateTime, SuspensionModel> suspensionMap = {};
  List<AttendanceModel> logs = [];
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  late AnimationController _glowController;
  late Animation<Color?> _glowAnimation;

  List<int> getYears() => List.generate(1, (i) => DateTime.now().year - i);
  List<DateTime> getDaysInMonth(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0);
    return List.generate(lastDay.day, (i) => DateTime(year, month, i + 1));
  }

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = ColorTween(
      begin: Colors.purple.withValues(alpha: 0.1),
      end: Colors.purple.withValues(alpha: 0.4),
    ).animate(_glowController);
    _loadInitialData();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    context.read<HolidayCubit>().getAllHolidays();
    context.read<SuspensionCubit>().getAllSuspensions();

    final authState = context.read<AuthCubit>().state;
    if (authState is AuthenticatedState) {
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
            attendanceMap = groupAttendance(filteredLogs, suspensionMap);
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
                            !isSmallScreen
                                ? 'Click on any WFH row to view targets and accomplishments. Use the Export button to generate your DTR.'
                                : 'View your attendance here',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                          trailing: ExportButton(
                            selectedYear: selectedYear,
                            selectedMonth: selectedMonth,
                            holidayMap: holidayMap,
                            suspensionMap: suspensionMap,
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
                                  child: Scrollbar(
                                    controller: _scrollController,
                                    thumbVisibility: true,
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
                                          isSmallScreen: isSmallScreen,
                                          glowAnimation: _glowAnimation,
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
      },
    );
  }
}

Widget buildAttendanceRow({
  required BuildContext context,
  required GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey,
  required DateTime day,
  required Map<String, Map<String, String>> attendanceMap,
  required Map<DateTime, String> holidayMap,
  required Map<DateTime, SuspensionModel> suspensionMap,
  required bool isSmallScreen,
  required Animation<Color?> glowAnimation,
}) {
  final dateKey = DateFormat('yyyy-MM-dd').format(day);
  final data = attendanceMap[dateKey];
  final holidayName = holidayMap[DateTime(day.year, day.month, day.day)];
  final isWeekend =
      day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
  final isToday = DateUtils.isSameDay(day, DateTime.now());

  final rowColor =
      holidayName != null
          ? Colors.green.shade50
          : isWeekend
          ? Colors.grey.shade200
          : isToday
          ? Colors.yellow.withValues(alpha: 0.1)
          : null;

  final label = holidayName ?? (isWeekend ? 'Weekend' : '');
  final isNonWorkingDay = holidayName != null || isWeekend;

  final isSuspension = suspensionMap.containsKey(day);
  final suspensionModel = suspensionMap[day];

  if (isNonWorkingDay ||
      (isSuspension && suspensionModel?.isHalfday == false)) {
    String displayLabel = label;
    Color? effectiveRowColor = rowColor;

    if (isSuspension && suspensionModel?.isHalfday == false) {
      displayLabel = suspensionModel!.name;
      effectiveRowColor = Colors.orange.withValues(alpha: 0.1);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Container(
        decoration: BoxDecoration(
          color: effectiveRowColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade100, width: 1.5),
        ),
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
                displayLabel,
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
      ),
    );
  }

  final isWFH = data?['type']?.toLowerCase().contains('wfh') ?? false;

  String? displayTimeIn = data?['timeIn'];
  String? displayLunchOut = data?['lunchOut'];
  String? displayLunchIn = data?['lunchIn'];
  String? displayTimeOut = data?['timeOut'];
  String? displayType = data?['type'];

  if (isSuspension && suspensionModel!.isHalfday) {
    if (displayTimeIn != null && displayTimeIn != '—') {
      displayLunchOut = DateFormat('h:mm a').format(suspensionModel.datetime);
      // displayLunchIn = suspensionModel.name;
      // displayTimeOut = null;
      displayLunchIn = '-';
      displayTimeOut = '-';
    } else {
      displayTimeIn = '—';
      displayLunchOut = DateFormat('h:mm a').format(suspensionModel.datetime);
      // displayLunchIn = suspensionModel.name;
      // displayTimeOut = null;
      displayLunchIn = '-';
      displayTimeOut = '-';
    }
    displayType = 'suspension';
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 1.0),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap:
          isWFH
              ? () => _showRemarksDialog(
                context,
                scaffoldMessengerKey: scaffoldMessengerKey,
                day: day,
                timeInRemarks: data?['timeInRemarks'] ?? 'No targets specified',
                timeOutRemarks:
                    data?['timeOutRemarks'] ?? 'No accomplishments specified',
              )
              : null,
      child: AnimatedBuilder(
        animation: glowAnimation,
        builder: (context, child) {
          return Container(
            decoration:
                isWFH
                    ? BoxDecoration(
                      color: rowColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: glowAnimation.value ?? Colors.purple,
                        width: 1.5,
                      ),
                    )
                    : BoxDecoration(color: rowColor),
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
                  child: buildTimeCell(
                    displayTimeIn,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                Expanded(
                  child: buildTimeCell(
                    displayLunchOut,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                Expanded(
                  // flex:
                  //     // (displayType == 'suspension' && displayTimeOut == null)
                  //     //     ? 2
                  //     //     : 1,
                  child: buildTimeCell(
                    displayLunchIn,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                // if (displayType != 'suspension' ||
                //     displayType == 'suspension' && displayTimeOut != null)
                Expanded(
                  child: buildTimeCell(
                    displayTimeOut,
                    isSmallScreen: isSmallScreen,
                  ),
                ),
                Expanded(
                  child:
                      displayType != null
                          ? _buildBadge(displayType, smallScreen: isSmallScreen)
                          : const SizedBox.shrink(),
                ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

void _showRemarksDialog(
  BuildContext context, {
  required GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey,
  required DateTime day,
  required String timeInRemarks,
  required String timeOutRemarks,
}) {
  showDialog(
    context: context,
    builder:
        (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: Colors.white,
          titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          title: Text(
            'WFH Remarks - ${DateFormat('MMM dd, yyyy').format(day)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.teal.shade700,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Targets (Time In):',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    CopyFeedbackIconButton(
                      textToCopy: timeInRemarks,
                      tooltip: 'Copy Targets',
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  timeInRemarks,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Accomplishments (Time Out):',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    CopyFeedbackIconButton(
                      textToCopy: timeOutRemarks,
                      tooltip: 'Copy Accomplishments',
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  timeOutRemarks,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(color: Colors.teal.shade700),
              ),
            ),
          ],
        ),
  );
}

Widget buildTimeCell(String? timeString, {required bool isSmallScreen}) {
  if (timeString == null || timeString.trim() == '—') {
    return Text(
      '—',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
    );
  }

  final match = RegExp(
    r'^(\d{1,2}:\d{2})\s?(AM|PM)$',
  ).firstMatch(timeString.trim().toUpperCase());

  if (match != null && isSmallScreen) {
    final time = match.group(1)!;
    final period = match.group(2)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          time,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
        Text(
          period,
          style: const TextStyle(fontSize: 10, height: 1.1, color: Colors.grey),
          textAlign: TextAlign.center,
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
  final isSuspension = normalized.contains('suspension');

  Color color;
  String text;

  if (isSuspension) {
    color = Colors.orange;
    text = 'SUSP.';
  } else if (isWFH) {
    color = Colors.purple;
    text = 'WFH';
  } else {
    color = Colors.teal;
    text = 'BIO';
  }

  return Container(
    margin: EdgeInsets.only(left: 5),
    padding: const EdgeInsets.symmetric(vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(5),
    ),
    child: Center(
      child: Text(
        text,
        style: TextStyle(
          fontSize: smallScreen ? 8 : 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    ),
  );
}

class CopyFeedbackIconButton extends StatefulWidget {
  final String textToCopy;
  final String tooltip;

  const CopyFeedbackIconButton({
    super.key,
    required this.textToCopy,
    required this.tooltip,
  });

  @override
  State<CopyFeedbackIconButton> createState() => _CopyFeedbackIconButtonState();
}

class _CopyFeedbackIconButtonState extends State<CopyFeedbackIconButton> {
  bool copied = false;

  void _copyText() {
    Clipboard.setData(ClipboardData(text: widget.textToCopy));
    setState(() => copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        copied ? Icons.check_circle : Icons.copy,
        size: 20,
        color: copied ? Colors.green : Colors.teal,
      ),
      tooltip: widget.tooltip,
      onPressed: _copyText,
    );
  }
}
