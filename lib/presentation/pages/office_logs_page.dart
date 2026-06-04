import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/attendance_model.dart';
import 'package:racconnect/data/blocs/cubit/attendance_cubit.dart';
import 'package:racconnect/data/blocs/cubit/auth_cubit.dart';
import 'package:racconnect/data/blocs/cubit/holiday_cubit.dart';
import 'package:racconnect/data/blocs/cubit/suspension_cubit.dart';
import 'package:racconnect/data/models/suspension_model.dart';
import 'package:racconnect/data/models/profile_model.dart';
import 'package:racconnect/data/repositories/profile_repository.dart';
import 'package:racconnect/presentation/widgets/raw_logs_view.dart';
import 'package:racconnect/presentation/widgets/export_raw_logs_button.dart';
import 'package:racconnect/presentation/widgets/export_all_employees_logs_button.dart';
import 'package:racconnect/presentation/widgets/time_log_bottom_sheet.dart';
import 'package:racconnect/utility/attendance_rules.dart';
import 'package:skeletonizer/skeletonizer.dart';

class OfficeLogsPage extends StatefulWidget {
  const OfficeLogsPage({super.key});

  @override
  State<OfficeLogsPage> createState() => _OfficeLogsPageState();
}

class _OfficeLogsPageState extends State<OfficeLogsPage> {
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  List<ProfileModel> _profiles = [];
  ProfileModel? _selectedProfile;
  List<AttendanceModel> _employeeLogs = [];
  List<AttendanceModel> _filteredLogs = [];
  Map<DateTime, String> holidayMap = {};
  Map<DateTime, SuspensionModel> suspensionMap = {};

  bool _isLoadingLogs = false;
  bool _includeWFH = false;
  bool _includeAccomplishment = false;
  final TextEditingController _searchController = TextEditingController();

  List<int> getYears() => List.generate(2, (i) => DateTime.now().year - i);

  @override
  void initState() {
    super.initState();
    // Smart default: if before 15th, default to previous month
    final now = DateTime.now();
    if (now.day < 15) {
      final prevMonth = DateTime(now.year, now.month - 1);
      selectedMonth = prevMonth.month;
      selectedYear = prevMonth.year;
    }
    _loadGlobalData();
    _loadProfiles();
  }

  void _loadGlobalData() {
    context.read<HolidayCubit>().getAllHolidays(year: selectedYear);
    context.read<SuspensionCubit>().getAllSuspensions(year: selectedYear);
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
      monthDate: DateTime(selectedYear, selectedMonth),
    );

    if (!mounted) return;

    final state = cubit.state;
    if (state is GetEmployeeAttendanceSuccess) {
      setState(() {
        _employeeLogs = state.attendanceModels;
        _applyFilter();
        _isLoadingLogs = false;
      });
    } else {
      setState(() => _isLoadingLogs = false);
    }
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLogs = _employeeLogs.where((log) {
        final matchesQuery = log.remarks.toLowerCase().contains(query);

        if (!_includeWFH) {
          final isWFH = log.type.toLowerCase().contains('wfh');
          return matchesQuery && !isWFH;
        }

        return matchesQuery;
      }).toList();
    });
  }

  void _onDateFilterChanged({int? year, int? month}) {
    final int oldYear = selectedYear;
    setState(() {
      if (year != null) selectedYear = year;
      if (month != null) selectedMonth = month;
    });

    if (selectedYear != oldYear) {
      _loadGlobalData();
    }

    if (_selectedProfile != null) {
      _loadEmployeeLogs();
    }
  }

  void _showLogEditor({DateTime? date, AttendanceModel? log}) {
    if (_selectedProfile == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => TimeLogBottomSheet(
        log: log,
        initialDate: date,
        employeeNumber: _selectedProfile!.employeeNumber!,
      ),
    ).then((result) {
      if (result == true) {
        _loadEmployeeLogs();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 1000;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is AuthenticatedState && authState.user.role != 'Developer') {
          return const Center(
            child: Text('Restricted Access: Developer Only', style: TextStyle(color: Colors.red)),
          );
        }

        return BlocBuilder<HolidayCubit, HolidayState>(
          builder: (context, holidayState) {
            if (holidayState is GetAllHolidaySuccess) {
              holidayMap = {
                for (var h in holidayState.holidayModels)
                  DateTime(h.date.year, h.date.month, h.date.day): h.name,
              };
            }
            return BlocBuilder<SuspensionCubit, SuspensionState>(
              builder: (context, suspensionState) {
                if (suspensionState is GetAllSuspensionSuccess) {
                  suspensionMap = {
                    for (var s in suspensionState.filteredSuspensionModels)
                      DateTime(s.datetime.year, s.datetime.month, s.datetime.day): s,
                  };
                }
                return Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Stack(
                    children: [
                      Column(
                        children: [
                          _buildHeader(),
                          _buildFilters(),
                          Expanded(
                            child: isSmallScreen ? _buildStackedView() : _buildTwoColumnView(),
                          ),
                        ],
                      ),
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (_selectedProfile == null)
                              ExportAllEmployeesLogsButton(
                                selectedYear: selectedYear,
                                selectedMonth: selectedMonth,
                                profiles: _profiles,
                              ),
                            if (_selectedProfile != null)
                              ExportRawLogsButton(
                                selectedYear: selectedYear,
                                selectedMonth: selectedMonth,
                                logs: _filteredLogs,
                                isAllEmployees: true,
                                bioId: _selectedProfile?.bioId ?? _selectedProfile?.employeeNumber,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    return Card(
      color: Colors.deepPurple,
      child: ListTile(
        leading: const Icon(Icons.fingerprint, color: Colors.white, size: 30),
        title: const Text(
          'Office Logs',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        subtitle: const Text(
          'Manage DTR entries and view raw logs for specific employees',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 700;
    const double h = 45; // Uniform height
    final decoration = InputDecoration(
      filled: true,
      fillColor: Colors.grey[200],
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
    );

    if (isSmallScreen) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: h,
                    child: DropdownMenu<ProfileModel>(
                      expandedInsets: EdgeInsets.zero,
                      enableFilter: true,
                      requestFocusOnTap: true,
                      menuHeight: 350,
                      leadingIcon: const Icon(Icons.search, size: 18),
                      hintText: 'Select Employee...',
                      inputDecorationTheme: InputDecorationTheme(
                        filled: true,
                        fillColor: Colors.grey[200],
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      dropdownMenuEntries: _profiles.map((p) {
                        return DropdownMenuEntry(value: p, label: '${p.lastName}, ${p.firstName} (${p.employeeNumber})');
                      }).toList(),
                      onSelected: (val) {
                        setState(() => _selectedProfile = val);
                        _loadEmployeeLogs();
                      },
                    ),
                  ),
                ),
                if (_selectedProfile != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedProfile = null;
                        _employeeLogs = [];
                        _filteredLogs = [];
                      });
                    },
                    icon: const Icon(Icons.close, color: Colors.red),
                    tooltip: 'Clear Selection',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: h,
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: selectedMonth,
                      decoration: decoration.copyWith(labelText: 'Month', labelStyle: const TextStyle(fontSize: 12)),
                      items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(DateFormat('MMM').format(DateTime(0, i + 1)), style: const TextStyle(fontSize: 13)))),
                      onChanged: (val) => _onDateFilterChanged(month: val),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: h,
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedYear,
                      decoration: decoration.copyWith(labelText: 'Year', labelStyle: const TextStyle(fontSize: 12)),
                      items: getYears().map((y) => DropdownMenuItem(value: y, child: Text('$y', style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) => _onDateFilterChanged(year: val),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildAlignedSwitch(
              label: 'Include WFH logs?',
              value: _includeWFH,
              onChanged: (val) {
                setState(() {
                  _includeWFH = val;
                  _applyFilter();
                });
              },
            ),
            const SizedBox(height: 8),
            _buildAlignedSwitch(
              label: 'Show Accomplishments?',
              value: _includeAccomplishment,
              onChanged: (val) => setState(() => _includeAccomplishment = val),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: h,
                  child: DropdownMenu<ProfileModel>(
                    expandedInsets: EdgeInsets.zero,
                    enableFilter: true,
                    requestFocusOnTap: true,
                    menuHeight: 350,
                    leadingIcon: const Icon(Icons.search, size: 18),
                    hintText: 'Select Employee...',
                    inputDecorationTheme: InputDecorationTheme(
                      filled: true,
                      fillColor: Colors.grey[200],
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                    dropdownMenuEntries: _profiles.map((p) {
                      return DropdownMenuEntry(value: p, label: '${p.lastName}, ${p.firstName} (${p.employeeNumber})');
                    }).toList(),
                    onSelected: (val) {
                      setState(() => _selectedProfile = val);
                      _loadEmployeeLogs();
                    },
                  ),
                ),
              ),
              if (_selectedProfile != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedProfile = null;
                      _employeeLogs = [];
                      _filteredLogs = [];
                    });
                  },
                  icon: const Icon(Icons.close, color: Colors.red),
                  tooltip: 'Clear Selection',
                ),
              ],
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: h,
                  child: DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: selectedMonth,
                    decoration: decoration.copyWith(labelText: 'Month', labelStyle: const TextStyle(fontSize: 12)),
                    items: List.generate(12, (i) => DropdownMenuItem(value: i + 1, child: Text(DateFormat('MMM').format(DateTime(0, i + 1)), style: const TextStyle(fontSize: 13)))),
                    onChanged: (val) => _onDateFilterChanged(month: val),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: h,
                  child: DropdownButtonFormField<int>(
                    initialValue: selectedYear,
                    decoration: decoration.copyWith(labelText: 'Year', labelStyle: const TextStyle(fontSize: 12)),
                    items: getYears().map((y) => DropdownMenuItem(value: y, child: Text('$y', style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (val) => _onDateFilterChanged(year: val),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _buildAlignedSwitch(
                  label: 'Include WFH logs?',
                  value: _includeWFH,
                  onChanged: (val) {
                    setState(() {
                      _includeWFH = val;
                      _applyFilter();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _buildAlignedSwitch(
                  label: 'Show Accomplishments?',
                  value: _includeAccomplishment,
                  onChanged: (val) => setState(() => _includeAccomplishment = val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlignedSwitch({required String label, required bool value, required ValueChanged<bool> onChanged}) {
    return Container(
      height: 45,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Transform.scale(
            scale: 0.7,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: Colors.deepPurple.withValues(alpha: 0.5),
              activeThumbColor: Colors.deepPurple,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              textAlign: TextAlign.left,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStackedView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildDtrCard(isSmallScreen: true),
          const SizedBox(height: 8),
          _buildRawLogsCard(isSmallScreen: true),
        ],
      ),
    );
  }

  Widget _buildTwoColumnView() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildDtrCard(isSmallScreen: false)),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: _buildRawLogsCard(isSmallScreen: false)),
      ],
    );
  }

  Widget _buildDtrCard({required bool isSmallScreen}) {
    Widget content = Skeletonizer(
      enabled: _isLoadingLogs,
      child: _selectedProfile == null
          ? _buildEmptyState('Select an employee to view DTR', 'assets/images/dog.png')
          : _buildDtrTable(),
    );

    return Card(
      color: Colors.white,
      child: Column(
        mainAxisSize: isSmallScreen ? MainAxisSize.min : MainAxisSize.max,
        children: [
          const ListTile(
            leading: Icon(Icons.calendar_view_month),
            title: Text('DTR View', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          if (isSmallScreen) content else Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildRawLogsCard({required bool isSmallScreen}) {
    Widget content = Skeletonizer(
      enabled: _isLoadingLogs,
      child: _selectedProfile == null
          ? _buildEmptyState('No employee selected', 'assets/images/cat.png')
          : RawLogsView(
              logs: _filteredLogs,
              isLoading: false,
              showEmployeeNumber: false,
              showAccomplishment: _includeAccomplishment,
              isSmallScreen: isSmallScreen,
              onLogTap: (log) => _showLogEditor(log: log),
            ),
    );

    return Card(
      color: Colors.white,
      child: Column(
        mainAxisSize: isSmallScreen ? MainAxisSize.min : MainAxisSize.max,
        children: [
          const ListTile(
            leading: Icon(Icons.list_alt),
            title: Text('Raw Logs', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Divider(height: 1),
          if (isSmallScreen) content else Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, String assetPath) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                assetPath,
                height: 120,
                opacity: const AlwaysStoppedAnimation(0.5),
              ),
              const SizedBox(height: 16),
              Text(message, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDtrTable() {
    final days = _getDaysInMonth(selectedYear, selectedMonth);

    // Group all filtered logs by date for efficient access
    final Map<String, List<AttendanceModel>> logsByDate = {};
    for (var log in _filteredLogs) {
      final dateKey = DateFormat('yyyy-MM-dd').format(log.timestamp);
      logsByDate.putIfAbsent(dateKey, () => []).add(log);
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(1.2), // Day
            1: FlexColumnWidth(1.6), // AM IN
            2: FlexColumnWidth(1.6), // AM OUT
            3: FlexColumnWidth(1.6), // PM IN
            4: FlexColumnWidth(1.6), // PM OUT
            5: FlexColumnWidth(1.4), // Remarks (Narrower)
          },
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey[300]!, width: 0.5),
          ),
          children: [
            // Header Row
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[100]),
              children: [
                _buildHeaderCell('Day'),
                _buildHeaderCell('AM IN'),
                _buildHeaderCell('AM OUT'),
                _buildHeaderCell('PM IN'),
                _buildHeaderCell('PM OUT'),
                _buildHeaderCell('Remarks'),
              ],
            ),
            // Data Rows
            ...days.map((day) {
              final dateKey = DateFormat('yyyy-MM-dd').format(day);
              final dayLogs = logsByDate[dateKey] ?? [];
              final grouped = AttendanceRules.groupDayLogs(dayLogs);
              final remarksData = _getRemarksDataForDay(day);

              return TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      DateFormat('dd (EEE)').format(day),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  _buildTableTimeCell(day, grouped['amIn'], 'amIn'),
                  _buildTableTimeCell(day, grouped['amOut'], 'amOut'),
                  _buildTableTimeCell(day, grouped['pmIn'], 'pmIn'),
                  _buildTableTimeCell(day, grouped['pmOut'], 'pmOut'),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 2.0),
                    child: remarksData != null
                        ? Tooltip(
                            message: remarksData['detail'] ?? '',
                            child: Text(
                              remarksData['label'] ?? '',
                              style: const TextStyle(
                                fontSize: 9,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Map<String, String>? _getRemarksDataForDay(DateTime day) {
    final dateKey = DateTime(day.year, day.month, day.day);

    if (holidayMap.containsKey(dateKey)) {
      return {
        'label': 'Holiday',
        'detail': holidayMap[dateKey]!,
      };
    }

    if (suspensionMap.containsKey(dateKey)) {
      final s = suspensionMap[dateKey]!;
      return {
        'label': 'Suspension',
        'detail': '${s.name}${s.isHalfday ? ' (Half-day)' : ''}',
      };
    }

    if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
      return {
        'label': 'Weekend',
        'detail': DateFormat('EEEE').format(day),
      };
    }

    return null;
  }

  Widget _buildHeaderCell(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableTimeCell(DateTime day, AttendanceModel? log, String type) {
    final bool isMissing = log == null;
    final bool isWorkday = _isWorkday(day);
    final bool shouldHighlight = isMissing && isWorkday;

    return InkWell(
      onTap: () => _showLogEditor(date: day, log: log),
      child: Container(
        height: 40,
        alignment: Alignment.center,
        color: shouldHighlight ? Colors.red.withValues(alpha: 0.1) : null,
        child: Text(
          AttendanceRules.formatTime(log),
          style: TextStyle(
            color: log != null
                ? Colors.black
                : (shouldHighlight ? Colors.red[700] : Colors.grey[400]),
            fontSize: 11,
            fontWeight: shouldHighlight ? FontWeight.bold : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  bool _isWorkday(DateTime day) {
    // 1. Check if weekend
    if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
      return false;
    }

    // 2. Check if holiday
    final dateKey = DateTime(day.year, day.month, day.day);
    if (holidayMap.containsKey(dateKey)) {
      return false;
    }

    // 3. Check if suspension
    if (suspensionMap.containsKey(dateKey)) {
      // You might want to check the suspension time, but for now we assume whole day
      return false;
    }

    return true;
  }

  List<DateTime> _getDaysInMonth(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0);
    return List.generate(lastDay.day, (i) => DateTime(year, month, i + 1));
  }
}
