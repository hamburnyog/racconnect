import 'package:flutter/material.dart';
import 'package:racconnect/presentation/widgets/mobile_button.dart';
import 'package:racconnect/utility/offline_mode_provider.dart';

class ClockInButton extends StatelessWidget {
  final bool lockClockIn;
  final VoidCallback onPressed;
  final int timeLogsToday;

  const ClockInButton({
    super.key,
    required this.lockClockIn,
    required this.onPressed,
    required this.timeLogsToday,
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 700;
    final offlineMode = OfflineModeProvider.of(context)?.isOfflineMode ?? false;

    Widget icon;
    String label;
    Color? backgroundColor;
    Color? foregroundColor;

    if (timeLogsToday % 2 != 0) {
      icon = const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
      );
      label = 'Working..';
    } else if (timeLogsToday >= 2) {
      icon = const Icon(Icons.check);
      label = 'WFH';

      foregroundColor = Colors.teal;
    } else {
      icon = const Icon(Icons.more_time);
      label = 'WFH';
    }

    final tooltipMessage = offlineMode
        ? 'WFH attendance is disabled in offline mode'
        : lockClockIn
            ? 'Complete your profile to clock in.'
            : 'Click to clock in for WFH.';

    return Tooltip(
      message: tooltipMessage,
      child: MobileButton(
        isSmallScreen: isSmallScreen,
        onPressed: offlineMode || lockClockIn ? null : onPressed,
        icon: icon,
        label: label,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
      ),
    );
  }
}
