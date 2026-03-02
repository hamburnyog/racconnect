import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/signatory_model.dart';
import 'package:racconnect/data/models/suspension_model.dart';
import 'package:racconnect/logic/cubit/attendance_cubit.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';
import 'package:racconnect/logic/cubit/signatory_cubit.dart';
import 'package:racconnect/presentation/widgets/mobile_button.dart';
import 'package:racconnect/utility/generate_excel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart'; // For error logging

class ExportButton extends StatefulWidget {
  final int selectedYear;
  final int selectedMonth;
  final Map<DateTime, String> holidayMap;
  final Map<DateTime, SuspensionModel> suspensionMap;
  final Map<DateTime, String> leaveMap; // Add leaveMap
  final Map<DateTime, String> travelMap; // Add travelMap

  const ExportButton({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
    required this.holidayMap,
    required this.suspensionMap,
    required this.leaveMap, // Add leaveMap parameter
    required this.travelMap, // Add travelMap parameter
  });

  @override
  State<ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends State<ExportButton> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 700;

    final authState = context.read<AuthCubit>().state;
    final profile =
        authState is AuthenticatedState ? authState.user.profile : null;
    final employeeNumber = profile?.employeeNumber ?? '';
    final employmentStatus = profile?.employmentStatus ?? '';
    final isProfileComplete = employeeNumber.isNotEmpty;
    final isCOS = employmentStatus == 'COS';

    final tooltipMessage =
        isProfileComplete
            ? "Export this month's DTR as Excel"
            : 'Complete your profile to export.';

    Future<void> handleExport() async {
      if (!isProfileComplete) return;

      final signatory = await _showSignatorySelectionDialog(profile!);
      if (signatory == null) return;
      if (!mounted) return;

      if (isCOS) {
        _showCOSExportOptions(profile, signatory);
      } else {
        await _performExport(profile, employeeNumber, null, signatory);
      }
    }

    return Tooltip(
      message: tooltipMessage,
      child: MobileButton(
        isSmallScreen: isSmallScreen,
        onPressed: isProfileComplete && !_isExporting ? handleExport : null,
        icon: Icon(_isExporting ? Icons.hourglass_bottom : Icons.download),
        label: _isExporting ? 'Exporting' : 'Export',
      ),
    );
  }

  Future<SignatoryModel?> _showSignatorySelectionDialog(profile) async {
    final signatoryCubit = context.read<SignatoryCubit>();
    if (profile.section != null) {
      signatoryCubit.getSignatoriesBySection(profile.section!);
    } else {
      signatoryCubit.getSignatories();
    }

    return showDialog<SignatoryModel>(
      context: context,
      builder: (BuildContext context) {
        return BlocBuilder<SignatoryCubit, SignatoryState>(
          builder: (context, state) {
            return AlertDialog(
              title: const Text('Select Signatory'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Choose the signatory for this DTR:'),
                    const SizedBox(height: 16),
                    if (state is SignatoryLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (state is SignatoryLoadSuccess)
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: state.signatories.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final signatory = state.signatories[index];
                            return ListTile(
                              title: Text(signatory.name),
                              subtitle: Text(signatory.designation),
                              onTap: () => Navigator.of(context).pop(signatory),
                            );
                          },
                        ),
                      )
                    else if (state is SignatoryError)
                      Text('Error: ${state.message}')
                    else
                      const Text('No signatories found.'),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showCOSExportOptions(
    profile,
    SignatoryModel selectedSignatory,
  ) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Period'),
          content: const Text('Choose the period for the DTR:'),
          actions: <Widget>[
            TextButton(
              child: const Text('First Half (1-15)'),
              onPressed: () {
                Navigator.of(context).pop();
                _performExport(
                  profile,
                  profile.employeeNumber ?? '',
                  'first',
                  selectedSignatory,
                );
              },
            ),
            TextButton(
              child: const Text('Second Half (16-last day)'),
              onPressed: () {
                Navigator.of(context).pop();
                _performExport(
                  profile,
                  profile.employeeNumber ?? '',
                  'second',
                  selectedSignatory,
                );
              },
            ),
            TextButton(
              child: const Text('Whole Month'),
              onPressed: () {
                Navigator.of(context).pop();
                _performExport(
                  profile,
                  profile.employeeNumber ?? '',
                  'whole',
                  selectedSignatory,
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _performExport(
    profile,
    String employeeNumber,
    String? period,
    SignatoryModel? signatory,
  ) async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final attendanceCubit = context.read<AttendanceCubit>();

    try {
      final selectedDate = DateTime(widget.selectedYear, widget.selectedMonth);

      // Show loading indicator
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Exporting DTR to Excel...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Determine date range based on period
      DateTime? startDate;
      DateTime? endDate;

      if (period == 'first') {
        // First half of the month (1st to 15th)
        startDate = DateTime(widget.selectedYear, widget.selectedMonth, 1);
        endDate = DateTime(widget.selectedYear, widget.selectedMonth, 15);
      } else if (period == 'second') {
        // Second half of the month (16th to end of month)
        startDate = DateTime(widget.selectedYear, widget.selectedMonth, 16);
        endDate = DateTime(
          widget.selectedYear,
          widget.selectedMonth + 1,
          1,
        ).subtract(const Duration(days: 1));
      } else if (period == 'whole') {
        // Whole month - set startDate and endDate to full month range
        startDate = DateTime(widget.selectedYear, widget.selectedMonth, 1);
        endDate = DateTime(
          widget.selectedYear,
          widget.selectedMonth + 1,
          1,
        ).subtract(const Duration(days: 1));
      }
      // For null period (non-COS users), startDate and endDate remain null

      final monthlyLogs = await attendanceCubit.attendanceRepository
          .getEmployeeAttendanceForMonth(employeeNumber, selectedDate);


      final filePath = await generateExcel(
        selectedDate,
        profile,
        monthlyLogs,
        widget.holidayMap,
        widget.suspensionMap,
        widget.leaveMap, // Add leaveMap
        widget.travelMap, // Add travelMap
        startDate: startDate,
        endDate: endDate,
        signatory: signatory,
      );

      if (!mounted) {
        setState(() {
          _isExporting = false;
        });
        return;
      }

      if (filePath != null && (Platform.isAndroid || Platform.isIOS)) {
        final file = XFile(filePath);

        ShareResult result;
        if (Platform.isIOS) {
          // On iOS, we need to provide the sharePositionOrigin for the share sheet
          final box = context.findRenderObject() as RenderBox?;
          if (box != null) {
            result = await SharePlus.instance.share(
              ShareParams(
                subject:
                    'DTR Excel file - ${DateFormat('MMMM yyyy').format(selectedDate)}',
                files: [file],
                sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size,
              ),
            );
          } else {
            // Fallback if we can't get the context size
            result = await SharePlus.instance.share(
              ShareParams(
                subject:
                    'DTR Excel file - ${DateFormat('MMMM yyyy').format(selectedDate)}',
                files: [file],
              ),
            );
          }
        } else {
          // For Android, no special positioning needed
          result = await SharePlus.instance.share(
            ShareParams(
              subject:
                  'DTR Excel file - ${DateFormat('MMMM yyyy').format(selectedDate)}',
              files: [file],
            ),
          );
        }

        if (!mounted) {
          setState(() {
            _isExporting = false;
          });
          return;
        }

        scaffoldMessenger.showSnackBar(
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
    } catch (e) {
      if (kDebugMode) {
      }
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error exporting DTR: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
}
