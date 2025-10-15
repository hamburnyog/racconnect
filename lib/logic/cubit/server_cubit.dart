import 'dart:async';
import 'dart:math';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:racconnect/utility/server_check.dart';

part 'server_state.dart';

class ServerCubit extends Cubit<ServerState> {
  Timer? _timer;
  static const int _checkInterval = 3; // Fixed interval in seconds
  static const int _jitterRange = 1; // Jitter range in seconds (+/-)

  ServerCubit() : super(ServerInitial()) {
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    
    // Add jitter to prevent thundering herd
    final jitter = Random().nextInt(_jitterRange * 2) - _jitterRange;
    final interval = (_checkInterval + jitter).clamp(1, _checkInterval + _jitterRange);
    
    _timer = Timer(Duration(seconds: interval), () {
      checkServerStatus();
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }

  void checkServerStatus() async {
    final reachable = await isServerReachable();
    if (reachable) {
      emit(ServerConnected());
    } else {
      emit(ServerDisconnected());
    }
    _startTimer(); // Schedule next check
  }
}