
import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:racconnect/data/models/user_model.dart';
import 'package:racconnect/data/repositories/accomplishment_repository.dart';
import 'package:racconnect/data/repositories/attendance_repository.dart';
import 'package:racconnect/data/repositories/auth_repository.dart';
import 'package:racconnect/logic/cubit/internet_cubit.dart';
import 'package:racconnect/data/models/attendance_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MigrateRemarksButton extends StatefulWidget {
  final int selectedYear;
  final int selectedMonth;
  final VoidCallback onRefresh;

  const MigrateRemarksButton({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
    required this.onRefresh,
  });

  @override
  State<MigrateRemarksButton> createState() => _MigrateRemarksButtonState();
}

class _MigrateRemarksButtonState extends State<MigrateRemarksButton> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 135,
      right: 5,
      child: FloatingActionButton(
        onPressed: () {
          final migration = _Migration(
            context: context,
            selectedYear: widget.selectedYear,
            selectedMonth: widget.selectedMonth,
            internetCubit: context.read<InternetCubit>(),
            onImportSuccess: widget.onRefresh,
          );
          migration.startMigration();
        },
        tooltip: 'Migrate Remarks',
        child: const Icon(Icons.sync),
      ),
    );
  }
}

class _Migration {
  final BuildContext context;
  final int selectedYear;
  final int selectedMonth;
  final InternetCubit internetCubit;
  final VoidCallback? onImportSuccess;
  final AuthRepository authRepo = AuthRepository();
  final AttendanceRepository attendanceRepo = AttendanceRepository();
  final AccomplishmentRepository accomplishmentRepo = AccomplishmentRepository();

  _Migration({
    required this.context,
    required this.selectedYear,
    required this.selectedMonth,
    required this.internetCubit,
    this.onImportSuccess,
  });

  final ValueNotifier<double> progressNotifier = ValueNotifier(0.0);
  final ValueNotifier<String> statusNotifier = ValueNotifier('Preparing...');
  late BuildContext dialogContext;
  bool _isPaused = false;
  late StreamSubscription internetSub;

  Future<void> startMigration() async {
    _showProgressDialog();

    internetSub = internetCubit.stream.listen((state) {
      if (state is InternetDisconnected) {
        _isPaused = true;
        if (context.mounted) {
          try {
            Navigator.of(dialogContext).pop(); // hide dialog
          } catch (_) {}
        }
      } else if (state is InternetConnected) {
        if (_isPaused) {
          _isPaused = false;
          _showProgressDialog(); // re-show dialog
        }
      }
    });

    try {
      log('Starting migration...');
      List<UserModel> users = await authRepo.getUsers();
      List<UserModel> usersWithRole =
          users.where((user) => user.role != null && user.role!.isNotEmpty).toList();
      log('Found ${usersWithRole.length} users with roles.');

      int totalUsers = usersWithRole.length;
      int processedUsers = 0;

      for (var user in usersWithRole) {
        if (user.profile?.employeeNumber == null) {
          log('Skipping user ${user.name} because of missing employee number.');
          continue;
        }
        log('Processing user ${user.name} (${user.profile!.employeeNumber!})');

        List<AttendanceModel> attendance = await attendanceRepo
            .getEmployeeAttendance(user.profile!.employeeNumber!);

        List<AttendanceModel> wfhAttendance = attendance
            .where((log) =>
                log.type.toLowerCase().contains('wfh') &&
                log.timestamp.year == selectedYear &&
                log.timestamp.month == selectedMonth)
            .toList();
        log('Found ${wfhAttendance.length} WFH attendance logs for ${user.name}.');

        var groupedByDay = <DateTime, List<AttendanceModel>>{};
        for (var log in wfhAttendance) {
          final day = DateTime(log.timestamp.year, log.timestamp.month, log.timestamp.day);
          groupedByDay.putIfAbsent(day, () => []).add(log);
        }

        for (var day in groupedByDay.keys) {
          final logsForDay = groupedByDay[day]!;
          logsForDay.sort((a, b) => a.timestamp.compareTo(b.timestamp));

          final existingAccomplishments = await accomplishmentRepo
              .getEmployeeAccomplishments(user.profile!.employeeNumber!, day, day);

          String target = logsForDay.first.remarks;
          String accomplishment =
              logsForDay.length > 1 ? logsForDay.last.remarks : '';

          if (target.isNotEmpty || accomplishment.isNotEmpty) {
            if (existingAccomplishments.isEmpty) {
              log('Creating accomplishment for ${user.name} on $day');
              log('Target: $target');
              log('Accomplishment: $accomplishment');
              try {
                await accomplishmentRepo.addAccomplishment(
                  employeeNumber: user.profile!.employeeNumber!,
                  date: day,
                  target: target,
                  accomplishment: accomplishment,
                );
              } catch (e) {
                log('Error creating accomplishment for ${user.name} on $day: $e');
              }
            } else {
              log('Updating accomplishment for ${user.name} on $day');
              log('Target: $target');
              log('Accomplishment: $accomplishment');
              try {
                await accomplishmentRepo.updateAccomplishment(
                  id: existingAccomplishments.first.id!,
                  employeeNumber: user.profile!.employeeNumber!,
                  date: day,
                  target: target,
                  accomplishment: accomplishment,
                );
              } catch (e) {
                log('Error updating accomplishment for ${user.name} on $day: $e');
              }
            }
          }
        }

        processedUsers++;
        progressNotifier.value = processedUsers / totalUsers;
        statusNotifier.value = 'Processed ${user.name}';
      }

      if (context.mounted) {
        Navigator.of(dialogContext).pop();
      }
      _showSnackBar('Remarks migration completed successfully!', true);
      onImportSuccess?.call();
    } catch (e) {
      log('An error occurred during migration: $e');
      if (context.mounted) {
        Navigator.of(dialogContext).pop();
      }
      _showSnackBar('An error occurred during migration: $e', false);
    } finally {
      await internetSub.cancel();
    }
  }

  void _showProgressDialog() {
    if (!context.mounted) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Migrating Remarks',
      pageBuilder: (BuildContext dialogCtx, _, __) {
        dialogContext = dialogCtx;
        return AlertDialog(
          content: SizedBox(
            height: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Migrating remarks...'),
                const SizedBox(height: 12),
                ValueListenableBuilder<double>(
                  valueListenable: progressNotifier,
                  builder:
                      (_, value, __) => LinearProgressIndicator(value: value),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<String>(
                  valueListenable: statusNotifier,
                  builder: (_, value, __) => Text(value),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnackBar(String message, bool isSuccess) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
      ),
    );
  }
}
