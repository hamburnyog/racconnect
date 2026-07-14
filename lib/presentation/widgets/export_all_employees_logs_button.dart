import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:racconnect/data/models/profile_model.dart';
import 'package:racconnect/data/repositories/attendance_repository.dart';
import 'package:share_plus/share_plus.dart';

class ExportAllEmployeesLogsButton extends StatefulWidget {
  final int selectedYear;
  final int selectedMonth;
  final List<ProfileModel> profiles;

  const ExportAllEmployeesLogsButton({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
    required this.profiles,
  });

  @override
  State<ExportAllEmployeesLogsButton> createState() => _ExportAllEmployeesLogsButtonState();
}

class _ExportAllEmployeesLogsButtonState extends State<ExportAllEmployeesLogsButton> {
  bool _isExporting = false;
  bool _includeWFH = false;
  List<String> _selectedEmployeeNumbers = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedEmployeeNumbers = widget.profiles
        .where((p) => p.employeeNumber != null)
        .map((p) => p.employeeNumber!)
        .toList();
  }

  Future<void> _showSelectionDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final filteredProfiles = widget.profiles.where((p) {
              final name = '${p.firstName} ${p.lastName}'.toLowerCase();
              return name.contains(_searchQuery.toLowerCase()) ||
                     (p.employeeNumber?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
            }).toList();

            return AlertDialog(
              title: const Text('Export All Logs'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search employees...',
                        prefixIcon: Icon(Icons.search),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedEmployeeNumbers = widget.profiles
                                  .where((p) => p.employeeNumber != null)
                                  .map((p) => p.employeeNumber!)
                                  .toList();
                            });
                          },
                          child: const Text('Select All'),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedEmployeeNumbers = [];
                            });
                          },
                          child: const Text('Deselect All'),
                        ),
                      ],
                    ),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredProfiles.length,
                        itemBuilder: (context, index) {
                          final profile = filteredProfiles[index];
                          final empNo = profile.employeeNumber;
                          if (empNo == null) return const SizedBox.shrink();
                          
                          return CheckboxListTile(
                            title: Text('${profile.firstName} ${profile.lastName}', style: const TextStyle(fontSize: 14)),
                            subtitle: Text(empNo, style: const TextStyle(fontSize: 12)),
                            value: _selectedEmployeeNumbers.contains(empNo),
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedEmployeeNumbers.add(empNo);
                                } else {
                                  _selectedEmployeeNumbers.remove(empNo);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const Divider(),
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
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  onPressed: _selectedEmployeeNumbers.isEmpty ? null : () {
                    Navigator.of(context).pop();
                    _showPeriodSelectionDialog();
                  },
                  child: const Text('Next'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showPeriodSelectionDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Period'),
          content: const Text('Choose the period for export:'),
          actions: <Widget>[
            TextButton(
              child: const Text('First Half (1-15)'),
              onPressed: () {
                Navigator.of(context).pop();
                _performExport('first');
              },
            ),
            TextButton(
              child: const Text('Second Half (16-end)'),
              onPressed: () {
                Navigator.of(context).pop();
                _performExport('second');
              },
            ),
            TextButton(
              child: const Text('Whole Month'),
              onPressed: () {
                Navigator.of(context).pop();
                _performExport('whole');
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _performExport(String period) async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final attendanceRepo = AttendanceRepository();

    try {
      final selectedDate = DateTime(widget.selectedYear, widget.selectedMonth);
      final allLogs = await attendanceRepo.getAllAttendanceForMonth(selectedDate);

      DateTime startDate;
      DateTime endDate;

      if (period == 'first') {
        startDate = DateTime.utc(widget.selectedYear, widget.selectedMonth, 1);
        endDate = DateTime.utc(widget.selectedYear, widget.selectedMonth, 15, 23, 59, 59);
      } else if (period == 'second') {
        startDate = DateTime.utc(widget.selectedYear, widget.selectedMonth, 16);
        endDate = DateTime.utc(widget.selectedYear, widget.selectedMonth + 1, 1).subtract(const Duration(seconds: 1));
      } else {
        startDate = DateTime.utc(widget.selectedYear, widget.selectedMonth, 1);
        endDate = DateTime.utc(widget.selectedYear, widget.selectedMonth + 1, 1).subtract(const Duration(seconds: 1));
      }

      final filteredLogs = allLogs.where((log) {
        final isInRange = log.timestamp.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
                          log.timestamp.isBefore(endDate.add(const Duration(seconds: 1)));
        
        final isSelectedEmployee = _selectedEmployeeNumbers.contains(log.employeeNumber);
        
        if (!_includeWFH) {
          final isWFH = log.type.toLowerCase().contains('wfh');
          return isInRange && isSelectedEmployee && !isWFH;
        }
        
        return isInRange && isSelectedEmployee;
      }).toList();

      // Sort by timestamp ascending
      filteredLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Create a map for quick bioId lookup
      final employeeToBioId = {
        for (var p in widget.profiles)
          if (p.employeeNumber != null) p.employeeNumber!: p.bioId ?? p.employeeNumber!
      };

      // Generate CSV content
      final buffer = StringBuffer();
      buffer.writeln('bio_id,time_logs');

      final dateFormat = DateFormat('MM/dd/yyyy HH:mm:ss');
      for (var log in filteredLogs) {
        final timestampStr = dateFormat.format(log.timestamp);
        final bioId = employeeToBioId[log.employeeNumber] ?? log.employeeNumber;
        buffer.writeln('$bioId,$timestampStr');
      }

      final csvContent = buffer.toString();
      final fileName = 'all_employees_logs_${widget.selectedYear}_${widget.selectedMonth}_$period.csv';

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
            subject: 'All Employees Logs Export - ${DateFormat('MMMM yyyy').format(selectedDate)}',
            files: [xFile],
            sharePositionOrigin: box != null ? box.localToGlobal(Offset.zero) & box.size : null,
          ),
        );
      } else {
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
        print('Error exporting all logs: $e');
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
      heroTag: 'exportAllEmployeesLogsFab',
      backgroundColor: Colors.white,
      onPressed: _isExporting ? null : _showSelectionDialog,
      child: _isExporting
          ? CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
            )
          : Icon(Icons.file_download, color: Theme.of(context).primaryColor),
    );
  }
}
