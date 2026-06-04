import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/blocs/cubit/attendance_cubit.dart';
import 'package:racconnect/data/models/attendance_model.dart';
import 'package:racconnect/data/models/profile_model.dart';
import 'package:racconnect/data/repositories/profile_repository.dart';
import 'package:racconnect/utility/group_attendance.dart';
import 'package:skeletonizer/skeletonizer.dart';

class EmployeeDtrView extends StatefulWidget {
  final int selectedYear;
  final int selectedMonth;

  const EmployeeDtrView({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
  });

  @override
  State<EmployeeDtrView> createState() => _EmployeeDtrViewState();
}

class _EmployeeDtrViewState extends State<EmployeeDtrView> {
  List<ProfileModel> _profiles = [];
  ProfileModel? _selectedProfile;
  List<AttendanceModel> _employeeLogs = [];
  bool _isLoadingLogs = false;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void didUpdateWidget(EmployeeDtrView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedYear != widget.selectedYear ||
        oldWidget.selectedMonth != widget.selectedMonth) {
      if (_selectedProfile != null) {
        _loadEmployeeLogs();
      }
    }
  }

  Future<void> _loadProfiles() async {
    try {
      final profiles = await ProfileRepository().getAllProfiles();
      setState(() {
        _profiles = profiles;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profiles: $e')),
        );
      }
    }
  }

  Future<void> _loadEmployeeLogs() async {
    if (_selectedProfile == null) return;
    setState(() => _isLoadingLogs = true);

    final employeeNumber = _selectedProfile!.employeeNumber;
    if (employeeNumber == null) return;

    final cubit = context.read<AttendanceCubit>();
    await cubit.getEmployeeAttendanceForMonth(
      employeeNumber: employeeNumber,
      monthDate: DateTime(widget.selectedYear, widget.selectedMonth),
    );

    if (!mounted) return;

    final state = cubit.state;
    if (state is GetEmployeeAttendanceSuccess) {
      setState(() {
        _employeeLogs = state.attendanceModels;
        _isLoadingLogs = false;
      });
    } else {
      setState(() => _isLoadingLogs = false);
    }
  }

  void _showLogEditor({DateTime? date, AttendanceModel? log, String? type}) {
    if (_selectedProfile == null) return;

    final timeController = TextEditingController(
      text: log != null ? DateFormat('HH:mm').format(log.timestamp) : '',
    );
    DateTime selectedDate = date ?? log?.timestamp ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(log == null ? 'Add Log' : 'Edit Log'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(DateFormat('MMMM dd, yyyy').format(selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                );
                if (d != null) {
                  selectedDate = DateTime(
                    d.year,
                    d.month,
                    d.day,
                    selectedDate.hour,
                    selectedDate.minute,
                  );
                }
              },
            ),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(
                labelText: 'Time (HH:mm)',
                hintText: 'e.g., 08:30 or 17:00',
              ),
              keyboardType: TextInputType.datetime,
            ),
          ],
        ),
        actions: [
          if (log != null)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _confirmDelete(log);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final timeParts = timeController.text.split(':');
              if (timeParts.length != 2) return;

              final hour = int.tryParse(timeParts[0]);
              final minute = int.tryParse(timeParts[1]);

              if (hour == null || minute == null) return;

              final newTimestamp = DateTime(
                selectedDate.year,
                selectedDate.month,
                selectedDate.day,
                hour,
                minute,
              );

              final cubit = context.read<AttendanceCubit>();
              final navigator = Navigator.of(context);
              if (log == null) {
                await cubit.uploadAttendance(
                  employeeNumber: _selectedProfile!.employeeNumber!,
                  timestamp: newTimestamp,
                );
              } else {
                await cubit.updateAttendance(
                  id: log.id!,
                  timestamp: newTimestamp,
                );
              }
              if (!mounted) return;
              navigator.pop();
              _loadEmployeeLogs();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(AttendanceModel log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Log'),
        content: const Text('Are you sure you want to delete this log entry?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final cubit = context.read<AttendanceCubit>();
              final navigator = Navigator.of(context);
              await cubit.deleteAttendance(log.id!);
              if (!mounted) return;
              navigator.pop();
              _loadEmployeeLogs();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = _getDaysInMonth(widget.selectedYear, widget.selectedMonth);
    final attendanceMap = groupAttendance(_employeeLogs, {});

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: DropdownMenu<ProfileModel>(
                  expandedInsets: EdgeInsets.zero,
                  enableFilter: true,
                  requestFocusOnTap: true,
                  hintText: 'Search Employee...',
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  dropdownMenuEntries: _profiles.map((p) {
                    return DropdownMenuEntry(
                      value: p,
                      label: '${p.lastName}, ${p.firstName} (${p.employeeNumber})',
                    );
                  }).toList(),
                  onSelected: (val) {
                    setState(() => _selectedProfile = val);
                    _loadEmployeeLogs();
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Skeletonizer(
            enabled: _isLoadingLogs,
            child: _selectedProfile == null
                ? const Center(child: Text('Please select an employee to view DTR'))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 20,
                        headingRowHeight: 40,
                        dataRowMinHeight: 30,
                        dataRowMaxHeight: 50,
                        columns: const [
                          DataColumn(label: Text('Day')),
                          DataColumn(label: Text('AM IN')),
                          DataColumn(label: Text('AM OUT')),
                          DataColumn(label: Text('PM IN')),
                          DataColumn(label: Text('PM OUT')),
                        ],
                        rows: days.map((day) {
                          final dateKey = DateFormat('yyyy-MM-dd').format(day);
                          final data = attendanceMap[dateKey];

                          return DataRow(cells: [
                            DataCell(Text(DateFormat('dd (EEE)').format(day))),
                            _buildTimeCell(day, data?['timeIn'], 'timeIn'),
                            _buildTimeCell(day, data?['lunchOut'], 'lunchOut'),
                            _buildTimeCell(day, data?['lunchIn'], 'lunchIn'),
                            _buildTimeCell(day, data?['timeOut'], 'timeOut'),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  DataCell _buildTimeCell(DateTime day, String? timeStr, String type) {
    final hasTime = timeStr != null && timeStr != '—';
    
    AttendanceModel? log;
    if (hasTime) {
      log = _employeeLogs.where(
        (l) => DateFormat('yyyy-MM-dd').format(l.timestamp) == DateFormat('yyyy-MM-dd').format(day) &&
               _isLogOfType(l, type)
      ).firstOrNull;
    }

    return DataCell(
      InkWell(
        onTap: () => _showLogEditor(date: day, log: log, type: type),
        child: Container(
          padding: const EdgeInsets.all(4),
          alignment: Alignment.center,
          child: Text(
            timeStr ?? '—',
            style: TextStyle(
              color: hasTime ? Colors.black : Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  bool _isLogOfType(AttendanceModel log, String type) {
    final hour = log.timestamp.hour;
    if (type == 'timeIn') return hour < 10;
    if (type == 'lunchOut') return hour >= 10 && hour < 13;
    if (type == 'lunchIn') return hour >= 13 && hour < 15;
    if (type == 'timeOut') return hour >= 15;
    return false;
  }

  List<DateTime> _getDaysInMonth(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0);
    return List.generate(lastDay.day, (i) => DateTime(year, month, i + 1));
  }
}
