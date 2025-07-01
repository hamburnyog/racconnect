import 'package:flutter/material.dart';

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

    if (isWideScreen) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 150, maxHeight: 40),
        child: Tooltip(
          message: tooltipMessage,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.more_time),
            label: const Text('WFH'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            onPressed: lockClockIn ? null : onPressed,
          ),
        ),
      );
    } else {
      return Tooltip(
        message:
            lockClockIn
                ? 'Complete your profile to clock in.'
                : 'Click to clock in for WFH.',
        child: IconButton(
          onPressed: lockClockIn ? null : onPressed,
          icon: Icon(Icons.more_time),
          style: ElevatedButton.styleFrom(
            foregroundColor:
                lockClockIn ? Theme.of(context).primaryColor : Colors.white,
          ),
          tooltip: '',
        ),
      );
    }
  }
}
