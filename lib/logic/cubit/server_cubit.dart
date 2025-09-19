import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:racconnect/utility/server_check.dart';

part 'server_state.dart';

class ServerCubit extends Cubit<ServerState> {
  Timer? _timer;

  ServerCubit() : super(ServerInitial()) {
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
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
  }
}