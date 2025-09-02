import 'package:flutter/material.dart';
import 'package:racconnect/presentation/widgets/mobile_button.dart';

class ClockInButton extends StatelessWidget {
  final bool lockClockIn;
  final VoidCallback onPressed;

  const ClockInButton({
    super.key,
    required this.lockClockIn,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    final tooltipMessage =
        lockClockIn
            ? 'Complete your profile to clock in.'
            : 'Click to clock in for WFH.';

    return Tooltip(
      message: tooltipMessage,
      child: MobileButton(
        isSmallScreen: !isWideScreen,
        onPressed: lockClockIn ? null : onPressed,
        icon: Icons.more_time,
        label: 'WFH',
      ),
    );
  }
}
