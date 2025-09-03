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
  required Map<DateTime, String> leaveMap, // Add leaveMap parameter
  required Set<String> accomplishmentDates,
  required bool isSmallScreen,
  required Animation<Color?> greenGlowAnimation,
  required VoidCallback onRefreshAccomplishments,
}) {
  final dateKey = DateFormat('yyyy-MM-dd').format(day);
  final data = attendanceMap[dateKey];
  final hasAccomplishments = accomplishmentDates.contains(dateKey);
  final holidayName = holidayMap[DateTime(day.year, day.month, day.day)];
  final leaveName =
      leaveMap[DateTime(day.year, day.month, day.day)]; // Check for leave
  final isWeekend =
      day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;
  final isToday = DateUtils.isSameDay(day, DateTime.now());

  // Update row color to include purple for leaves
  final rowColor =
      holidayName != null
          ? Colors.green.shade50
          : leaveName != null
          ? Colors.purple.shade50
          : isWeekend
          ? Colors.grey.shade200
          : isToday
          ? Colors.yellow.withValues(alpha: 0.1)
          : null;

  // Update label to include leave name
  final label = holidayName ?? leaveName ?? (isWeekend ? 'Weekend' : '');
  // Update isNonWorkingDay to include leaves
  final isNonWorkingDay = holidayName != null || leaveName != null || isWeekend;

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
          !isWeekend
              ? () => showModalBottomSheet(
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
              )
              : null,
      child: AnimatedBuilder(
        animation: greenGlowAnimation,
        builder: (context, child) {
          return Container(
            decoration:
                hasAccomplishments
                    ? BoxDecoration(
                      color: rowColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: greenGlowAnimation.value ?? Colors.lightGreen,
                        width: 2.0,
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
                          ? buildBadge(displayType, smallScreen: isSmallScreen)
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
