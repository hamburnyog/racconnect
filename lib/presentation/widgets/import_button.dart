import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:racconnect/logic/cubit/attendance_cubit.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';
import 'package:racconnect/logic/cubit/internet_cubit.dart';
import 'package:racconnect/utility/import_attendance_button.dart';

class ImportButton extends StatelessWidget {
  final int selectedYear;
  final int selectedMonth;
  final Future<void> Function() onRefresh;

  const ImportButton({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
    required this.onRefresh,
  });

  bool get _isDesktop =>
      Platform.isWindows || Platform.isMacOS || Platform.isLinux;

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;

    final isDeveloper =
        authState is AuthenticatedState && authState.user.role == 'Developer';

    if (!_isDesktop || !isDeveloper) return const SizedBox.shrink();

    return Positioned(
      bottom: 70, // Position below the export button
      right: 5,
      child: Builder(
        builder: (localContext) {
          return FloatingActionButton(
            backgroundColor: Colors.white,
            onPressed: () async {
              final attendanceRepo =
                  localContext.read<AttendanceCubit>().attendanceRepository;
              final internetCubit = localContext.read<InternetCubit>();

              await AttendanceImport(
                context: localContext,
                attendanceRepo: attendanceRepo,
                selectedYear: selectedYear,
                selectedMonth: selectedMonth,
                internetCubit: internetCubit,
                onImportSuccess: () async {
                  await onRefresh();
                },
              ).pickAndImportFile();
            },
            child: const Icon(Icons.upload_file_sharp),
          );
        },
      ),
    );
  }
}
