import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

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
  List<String> _messages = [];
  String _currentMessage = 'Connecting';
  int _messageIndex = 0;
  String _ellipsis = '';
  Timer? _messageTimer;
  Timer? _ellipsisTimer;
  late StreamSubscription _timeStateSubscription;

  @override
  void initState() {
    super.initState();
    // Close any open dialogs or bottom sheets when this screen appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _closeAllDialogsAndBottomSheets();
      context.read<ServerCubit>().checkServerStatus();
    });
    
    // Listen to time state changes and navigate back when time is valid
    _timeStateSubscription = context.read<TimeCheckCubit>().stream.listen((state) {
      if (state is TimeValid) {
        // Navigate back to the main route when time is valid again
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
        });
      }
    });
    
    _loadMessages();
    _startEllipsisAnimation();
  }

  Future<void> _loadMessages() async {
    try {
      final String response = await rootBundle.loadString('assets/messages/disconnected_messages.json');
      final data = await json.decode(response);
      setState(() {
        _messages = List<String>.from(data['messages']);
        _currentMessage = _messages.isNotEmpty ? _messages[0] : 'Connecting';
      });
      _startMessageRotation();
    } catch (e) {
      // Fallback to default message if JSON loading fails
      setState(() {
        _currentMessage = 'Connecting';
      });
    }
  }

  void _startEllipsisAnimation() {
    _ellipsisTimer?.cancel();
    _ellipsisTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        if (_ellipsis.length < 3) {
          _ellipsis += '.';
        } else {
          _ellipsis = '';
        }
      });
    });
  }

  void _startMessageRotation() {
    if (_messages.isEmpty) return;
    
    _messageTimer?.cancel();
    _messageTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      setState(() {
        _messageIndex = (_messageIndex + 1) % _messages.length;
        _currentMessage = _messages[_messageIndex];
      });
    });
  }

  @override
  void dispose() {
    _messageTimer?.cancel();
    _ellipsisTimer?.cancel();
    _timeStateSubscription.cancel();
    super.dispose();
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
    bool isTimeTampered = timeState is TimeTampered;

    if (isTimeTampered) {
      title = 'Time Tampering Detected';
      message = 'System time has been modified.';
    } else {
      title = 'Connection Error';
      message = 'We\'re having trouble connecting to the server.';
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
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: isTimeTampered ? Colors.red : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(message),
              if (!isTimeTampered) ...[
                const SizedBox(height: 5),
                Text('$_currentMessage$_ellipsis'),
              ] else ...[
                const SizedBox(height: 10),
                Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 30,
                ),
                const SizedBox(height: 20),
                Text(
                  'Time difference: ${_formatDuration(timeState.timeDifference)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}