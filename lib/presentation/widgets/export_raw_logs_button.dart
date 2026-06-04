import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:racconnect/data/blocs/cubit/auth_cubit.dart';
import 'package:racconnect/data/models/attendance_model.dart';
import 'package:share_plus/share_plus.dart';

class ExportRawLogsButton extends StatefulWidget {
  final int selectedYear;
  final int selectedMonth;
  final List<AttendanceModel> logs;
  final bool isAllEmployees;
  final String? bioId;

  const ExportRawLogsButton({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
    required this.logs,
    this.isAllEmployees = false,
    this.bioId,
  });

  @override
  State<ExportRawLogsButton> createState() => _ExportRawLogsButtonState();
}

class _ExportRawLogsButtonState extends State<ExportRawLogsButton> {
  bool _isExporting = false;
  bool _includeWFH = false;

  Future<void> _showPeriodSelectionDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select the period to export:'),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    title: const Text('Include WFH logs', style: TextStyle(fontSize: 14)),
                    value: _includeWFH,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (bool? value) {
                      setState(() {
                        _includeWFH = value ?? false;
                      });
                    },
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('First Half (1-15)'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _performExport('first', _includeWFH);
                  },
                ),
                TextButton(
                  child: const Text('Second Half (16-end)'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _performExport('second', _includeWFH);
                  },
                ),
                TextButton(
                  child: const Text('Whole Month'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _performExport('whole', _includeWFH);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _performExport(String period, bool includeWFH) async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authState = context.read<AuthCubit>().state;

    if (authState is! AuthenticatedState) {
      if (mounted) setState(() => _isExporting = false);
      return;
    }

    try {
      DateTime startDate;
      DateTime endDate;

      if (period == 'first') {
        startDate = DateTime(widget.selectedYear, widget.selectedMonth, 1);
        endDate = DateTime(widget.selectedYear, widget.selectedMonth, 15, 23, 59, 59);
      } else if (period == 'second') {
        startDate = DateTime(widget.selectedYear, widget.selectedMonth, 16);
        endDate = DateTime(widget.selectedYear, widget.selectedMonth + 1, 1).subtract(const Duration(seconds: 1));
      } else {
        startDate = DateTime(widget.selectedYear, widget.selectedMonth, 1);
        endDate = DateTime(widget.selectedYear, widget.selectedMonth + 1, 1).subtract(const Duration(seconds: 1));
      }

      final filteredLogs = widget.logs.where((log) {
        final isInRange = log.timestamp.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
                          log.timestamp.isBefore(endDate.add(const Duration(seconds: 1)));
        
        if (!includeWFH) {
          final isWFH = log.type.toLowerCase().contains('wfh');
          return isInRange && !isWFH;
        }
        
        return isInRange;
      }).toList();

      // Sort by timestamp ascending
      filteredLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Generate CSV content
      final buffer = StringBuffer();
      buffer.writeln('bio_id,time_logs');

      final dateFormat = DateFormat('MM/dd/yyyy HH:mm:ss');
      for (var log in filteredLogs) {
        final timestampStr = dateFormat.format(log.timestamp);
        final bioId = widget.bioId ?? log.employeeNumber;
        buffer.writeln('$bioId,$timestampStr');
      }

      final csvContent = buffer.toString();
      final fileName = 'raw_logs_${widget.selectedYear}_${widget.selectedMonth}_$period.csv';

      final directory = await getApplicationDocumentsDirectory();
      final filePath = p.join(directory.path, fileName);
      final file = File(filePath);
      await file.writeAsString(csvContent);

      if (!mounted) return;

      if (Platform.isAndroid || Platform.isIOS) {
        final xFile = XFile(filePath);
        final box = context.findRenderObject() as RenderBox?;
        
        await SharePlus.instance.share(
          ShareParams(
            subject: 'Raw Logs Export - ${DateFormat('MMMM yyyy').format(DateTime(widget.selectedYear, widget.selectedMonth))}',
            files: [xFile],
            sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
          ),
        );
      } else {
        // For desktop, show a success message and potentially open the folder
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('CSV exported to: $filePath'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () async {
                if (Platform.isMacOS) {
                  await Process.run('open', [directory.path]);
                } else if (Platform.isWindows) {
                  await Process.run('explorer', [directory.path]);
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error exporting raw logs: $e');
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error exporting logs: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      mini: true,
      heroTag: 'exportRawLogsFab_${widget.isAllEmployees}',
      backgroundColor: Theme.of(context).primaryColor,
      onPressed: _isExporting ? null : _showPeriodSelectionDialog,
      child: _isExporting
          ? const CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
          : const Icon(Icons.file_download, color: Colors.white),
    );
  }
}
