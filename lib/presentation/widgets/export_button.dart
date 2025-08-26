import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:racconnect/data/models/suspension_model.dart';
import 'package:racconnect/logic/cubit/attendance_cubit.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';
import 'package:racconnect/utility/generate_excel.dart';
import 'package:share_plus/share_plus.dart';

class ExportButton extends StatelessWidget {
  final int selectedYear;
  final int selectedMonth;
  final Map<DateTime, String> holidayMap;
  final Map<DateTime, SuspensionModel> suspensionMap;

  const ExportButton({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
    required this.holidayMap,
    required this.suspensionMap,
  });

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    final authState = context.read<AuthCubit>().state;
    final profile =
        authState is AuthenticatedState ? authState.user.profile : null;
    final employeeNumber = profile?.employeeNumber ?? '';
    final isProfileComplete = employeeNumber.isNotEmpty;

    final tooltipMessage =
        isProfileComplete
            ? "Export this month's DTR as Excel"
            : 'Complete your profile to export.';

    Future<void> handleExport() async {
      if (!isProfileComplete) return;

      final selectedDate = DateTime(selectedYear, selectedMonth);

      final monthlyLogs = await context
          .read<AttendanceCubit>()
          .attendanceRepository
          .getEmployeeAttendanceForMonth(employeeNumber, selectedDate);

      final filePath = await generateExcel(
        selectedDate,
        profile!,
        monthlyLogs,
        holidayMap,
        suspensionMap,
      );

      if (!context.mounted) return;

      if (filePath != null && (Platform.isAndroid || Platform.isIOS)) {
        final file = XFile(filePath);
        final box = context.findRenderObject() as RenderBox?;

        final result = await SharePlus.instance.share(
          ShareParams(
            text: 'Generated DTR Excel file',
            files: [file],
            sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
          ),
        );

        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor:
                result.status == ShareResultStatus.success
                    ? Colors.green
                    : Colors.red,
            content: Text(
              result.status == ShareResultStatus.success
                  ? 'File shared successfully!'
                  : 'Share canceled or failed',
            ),
          ),
        );
      }
    }

    if (isWideScreen) {
      return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 150, maxHeight: 40),
        child: Tooltip(
          message: tooltipMessage,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('Export'),
            onPressed: isProfileComplete ? handleExport : null,
            style: ElevatedButton.styleFrom(
              foregroundColor: Theme.of(context).primaryColor,
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
      );
    } else {
      return Tooltip(
        message: tooltipMessage,
        child: IconButton(
          onPressed: isProfileComplete ? handleExport : null,
          icon: const Icon(Icons.file_download),
          color: Colors.white,
          tooltip: '',
        ),
      );
    }
  }
}
