import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:racconnect/logic/cubit/server_cubit.dart';
import 'package:racconnect/logic/cubit/time_check_cubit.dart';
import 'package:racconnect/presentation/widgets/logo_widget.dart';

class DisconnectedScreen extends StatefulWidget {
  const DisconnectedScreen({super.key});

  @override
  State<DisconnectedScreen> createState() => _DisconnectedScreenState();
}

class _DisconnectedScreenState extends State<DisconnectedScreen> {
  @override
  void initState() {
    super.initState();
    // Close any open dialogs or bottom sheets when this screen appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _closeAllDialogsAndBottomSheets();
      context.read<ServerCubit>().checkServerStatus();
    });
  }

  void _closeAllDialogsAndBottomSheets() {
    try {
      // Close all open dialogs and bottom sheets by popping the navigation stack
      Navigator.of(context, rootNavigator: true).popUntil((route) {
        return route.isFirst;
      });
    } catch (e) {
      // Ignore any errors that might occur when trying to close dialogs
    }
  }

  String _formatDuration(Duration duration) {
    final int days = duration.inDays;
    final int hours = duration.inHours.remainder(24);
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);

    final List<String> parts = [];

    // Calculate approximate years and months
    final int years = (days / 365).floor();
    final int remainingDaysAfterYears = days % 365;
    final int months = (remainingDaysAfterYears / 30).floor();
    final int remainingDays = remainingDaysAfterYears % 30;

    if (years > 0) {
      parts.add('${years}y');
    }

    if (months > 0) {
      parts.add('${months}m');
    }

    if (remainingDays > 0) {
      parts.add('${remainingDays}d');
    }

    if (hours > 0) {
      parts.add('${hours}h');
    }

    if (minutes > 0) {
      parts.add('${minutes}m');
    }

    if (seconds > 0) {
      parts.add('${seconds}s');
    }

    return parts.isNotEmpty ? parts.join(' ') : '0s';
  }

  @override
  Widget build(BuildContext context) {
    final timeState = context.watch<TimeCheckCubit>().state;

    String title = 'Connection Error';
    String message = 'We\'re having trouble connecting to the server.';
    String subMessage = 'Attempting to reconnect ...';

    if (timeState is TimeTampered) {
      title = 'Time Tampering Detected';
      message = 'System time has been modified.';
      subMessage = 'Please restore your system time to the correct time.';
    } else {
      title = 'Connection Error';
      message = 'We\'re having trouble connecting to the server.';
      subMessage = 'Attempting to reconnect ...';
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: LogoWithVersion(),
              ),
              Lottie.asset(
                'assets/animations/dino.json',
                fit: BoxFit.cover,
                height:
                    (!Platform.isAndroid && !Platform.isIOS)
                        ? MediaQuery.of(context).size.height * .3
                        : MediaQuery.of(context).size.height * .2,
                frameRate: FrameRate.max,
              ),
              const SizedBox(height: 20),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              Text(message),
              Text(subMessage),
              if (timeState is TimeTampered) ...[
                const SizedBox(height: 20),
                Text(
                  'Time difference: ${_formatDuration(timeState.timeDifference)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}