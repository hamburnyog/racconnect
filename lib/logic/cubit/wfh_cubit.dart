import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:racconnect/utility/pocketbase_client.dart';

part 'wfh_state.dart';

class WfhCubit extends Cubit<WfhState> {
  final PocketBase _pb = PocketBaseClient.instance;

  WfhCubit() : super(WfhInitial());

  Future<void> getInitialWfhCount() async {
    emit(WfhLoading());
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day).toUtc().toIso8601String();
    final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59).toUtc().toIso8601String();

    try {
      final result = await _pb.collection('attendance').getList(
            filter: 'timestamp >= "$startOfDay" && timestamp <= "$endOfDay" && remarks = "WFH"',
          );
      emit(WfhLoaded(result.totalItems));
    } catch (e) {
      emit(WfhError(e.toString()));
    }
  }

  void subscribeToWfhUpdates() {
    _pb.collection('attendance').subscribe('*', (e) {
      if (e.action == 'create' || e.action == 'delete' || e.action == 'update') {
        getInitialWfhCount();
      }
    });
  }

  @override
  Future<void> close() {
    _pb.collection('attendance').unsubscribe();
    return super.close();
  }
}
