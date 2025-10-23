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
    final startOfDay =
        DateTime(today.year, today.month, today.day).toUtc().toIso8601String();
    final endOfDay =
        DateTime(
          today.year,
          today.month,
          today.day,
          23,
          59,
          59,
        ).toUtc().toIso8601String();

    try {
      // Get ALL attendance records for today (both biometrics and WFH)
      final allAttendanceRecords = await _pb
          .collection('attendance')
          .getFullList(
            filter: 'timestamp >= "$startOfDay" && timestamp <= "$endOfDay"',
          );

      // Group records by employee number and date to apply biometric priority
      final recordsByEmployeeDate = <String, Map<DateTime, List<Map<String, dynamic>>>>{};
      for (var record in allAttendanceRecords) {
        final timestamp = DateTime.parse(record.data['timestamp']);
        final date = DateTime(timestamp.year, timestamp.month, timestamp.day);
        final empNum = record.data['employeeNumber'];
        
        recordsByEmployeeDate.putIfAbsent(empNum, () => <DateTime, List<Map<String, dynamic>>>{});
        recordsByEmployeeDate[empNum]!.putIfAbsent(date, () => []).add(record.data);
      }

      // Apply biometric priority: if both biometrics and WFH exist for same day, prioritize biometrics over WFH
      final wfhEmployeeNumbers = <String>{};
      for (var empEntry in recordsByEmployeeDate.entries) {
        final employeeNumber = empEntry.key;
        for (var dateEntry in empEntry.value.entries) {
          final dayRecords = dateEntry.value;
          final hasBiometrics = dayRecords.any((record) => 
              (record['type'] as String?)?.toLowerCase() == 'biometrics');
          final hasWFH = dayRecords.any((record) => 
              (record['type'] as String?)?.toLowerCase().contains('wfh') ?? false);
          
          if (hasWFH && !hasBiometrics) {
            wfhEmployeeNumbers.add(employeeNumber);
            break; // Found at least one WFH day for this employee
          }
        }
      }

      emit(WfhLoaded(wfhEmployeeNumbers.length));
    } catch (e) {
      emit(WfhError(e.toString()));
    }
  }

  void subscribeToWfhUpdates() {
    _pb.collection('attendance').subscribe('*', (e) {
      if (e.action == 'create' ||
          e.action == 'delete' ||
          e.action == 'update') {
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