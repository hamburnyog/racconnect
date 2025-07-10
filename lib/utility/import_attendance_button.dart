import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/repositories/attendance_repository.dart';
import 'package:racconnect/logic/cubit/internet_cubit.dart';

class AttendanceImport {
  final AttendanceRepository attendanceRepo;
  final BuildContext context;
  final int selectedYear;
  final int selectedMonth;
  final InternetCubit internetCubit;
  final VoidCallback? onImportSuccess;

  AttendanceImport({
    required this.context,
    required this.attendanceRepo,
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

  Future<void> pickAndImportFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
      dialogTitle: 'Select attendance file (.txt)',
      initialDirectory: '/storage/emulated/0/Download',
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final lines = await file.readAsLines();
    if (lines.isEmpty) {
      _showSnackBar('The selected file is empty.', false);
      return;
    }

    final filteredLines =
        lines.where((line) {
          final parts = line.split(',');
          if (parts.length < 3) return false;
          try {
            final date = DateFormat('MM/dd/yyyy').parseStrict(parts[1].trim());
            return date.year == selectedYear && date.month == selectedMonth;
          } catch (_) {
            return false;
          }
        }).toList();

    if (filteredLines.isEmpty) {
      _showSnackBar('No matching records for selected month.', false);
      return;
    }

    await _processBatch(filteredLines);
  }

  Future<void> _processBatch(List<String> initialLines) async {
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

    if (!context.mounted) return;

    _showProgressDialog();

    List<String> remaining = List.from(initialLines);
    int total = remaining.length;
    int success = 0, skipped = 0;
    final failedLog = <String>[];

    while (remaining.isNotEmpty) {
      while (_isPaused) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final nextRetry = <String>[];
      for (int i = 0; i < remaining.length; i++) {
        final line = remaining[i];
        final parts = line.split(',');
        if (parts.length < 3) {
          failedLog.add(line);
          continue;
        }

        try {
          final employeeNumber = parts[0].replaceFirst(RegExp(r'^0+'), '');
          final timestamp = DateFormat(
            'MM/dd/yyyy HH:mm:ss',
          ).parseStrict('${parts[1].trim()} ${parts[2].trim()}');

          final uploaded = await attendanceRepo.uploadAttendance(
            employeeNumber: employeeNumber,
            timestamp: timestamp,
          );

          if (uploaded == null) {
            skipped++;
          } else {
            success++;
          }
        } catch (_) {
          nextRetry.add(line);
        }

        final processed =
            success + skipped + failedLog.length + nextRetry.length;
        progressNotifier.value = processed / total;
        statusNotifier.value =
            '✅ $success | ⏭️ $skipped | 🔁 ${nextRetry.length}';
      }

      remaining = nextRetry;
    }

    if (context.mounted) {
      try {
        Navigator.of(dialogContext).pop();
      } catch (_) {}
    }

    await internetSub.cancel();
    _showSnackBar(
      'Biometric logs for the selected month have been imported!',
      true,
    );

    // ✅ call the callback if provided
    onImportSuccess?.call();

    await internetSub.cancel();
  }

  void _showProgressDialog() {
    if (!context.mounted) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Importing',
      pageBuilder: (BuildContext dialogCtx, _, __) {
        dialogContext = dialogCtx;
        return AlertDialog(
          content: SizedBox(
            height: 120,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Importing attendance...'),
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
