import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/suspension_model.dart';
import 'package:racconnect/presentation/widgets/accomplishment_bottom_sheet.dart';
import 'package:racconnect/utility/attendance_helpers.dart';

Widget buildAttendanceRow({
  required BuildContext context,
  required GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey,
  required DateTime day,
  required Map<String, Map<String, String>> attendanceMap,
  required Map<DateTime, String> holidayMap,
  required Map<DateTime, SuspensionModel> suspensionMap,
  required Map<DateTime, String> leaveMap,
  required Map<DateTime, String> travelMap,
  required Set<String> accomplishmentDates,
  required bool isSmallScreen,
  required Animation<Color?> greenGlowAnimation,
  required VoidCallback onRefreshAccomplishments,
}) {
  final dateKey = DateFormat('yyyy-MM-dd').format(day);
  final data = attendanceMap[dateKey];
  final hasAccomplishments = accomplishmentDates.contains(dateKey);
  final holidayName = holidayMap[DateTime(day.year, day.month, day.day)];
  final leaveName = leaveMap[DateTime(day.year, day.month, day.day)];
  final travelName = travelMap[DateTime(day.year, day.month, day.day)];
  final isWeekend =
      day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
  final isToday = DateUtils.isSameDay(day, DateTime.now());

  final rowColor =
      holidayName != null
          ? Colors.green.shade50
          : leaveName != null
          ? Colors.purple.shade50
          : travelName != null
          ? Colors.teal.shade50
          : isWeekend
          ? Colors.grey.shade200
          : isToday
          ? Colors.yellow.withValues(alpha: 0.1)
          : null;

  final label =
      holidayName ?? leaveName ?? travelName ?? (isWeekend ? 'Weekend' : '');
  final isNonWorkingDay =
      holidayName != null ||
      leaveName != null ||
      travelName != null ||
      isWeekend;
  final isSuspension = suspensionMap.containsKey(day);
  final suspensionModel = suspensionMap[day];

  String? displayTimeIn = data?['timeIn'];
  String? displayLunchOut = data?['lunchOut'];
  String? displayLunchIn = data?['lunchIn'];
  String? displayTimeOut = data?['timeOut'];
  String? displayType = data?['type'];

  if (isSuspension && suspensionModel?.isHalfday == true) {
    if (displayTimeIn != null && displayTimeIn != '—') {
      displayLunchOut = DateFormat('h:mm a').format(suspensionModel!.datetime);
      displayLunchIn = '-';
      displayTimeOut = '-';
    } else {
      displayTimeIn = '—';
      displayLunchOut = DateFormat('h:mm a').format(suspensionModel!.datetime);
      displayLunchIn = '-';
      displayTimeOut = '-';
    }
    displayType = 'suspension';
  }

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 1.0),
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        scrollControlDisabledMaxHeightRatio: 0.75,
        showDragHandle: true,
        useSafeArea: true,
        builder: (BuildContext builder) {
          return AccomplishmentBottomSheet(
            day: day,
            onAccomplishmentSaved: onRefreshAccomplishments,
          );
        },
      ),
      child: AnimatedBuilder(
        animation: greenGlowAnimation,
        builder: (context, child) {
          return Container(
            decoration: hasAccomplishments
                ? BoxDecoration(
                    color: rowColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: greenGlowAnimation.value ?? Colors.lightGreen,
                      width: 2.0,
                    ),
                  )
                : BoxDecoration(
                    color: rowColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade100,
                      width: 1.5,
                    ),
                  ),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: isNonWorkingDay
                ? Row(
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
                  )
                : Row(
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
                        child: buildTimeCell(
                          displayLunchIn,
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                      Expanded(
                        child: buildTimeCell(
                          displayTimeOut,
                          isSmallScreen: isSmallScreen,
                        ),
                      ),
                      Expanded(
                        child: displayType != null
                            ? buildBadge(displayType,
                                smallScreen: isSmallScreen)
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
