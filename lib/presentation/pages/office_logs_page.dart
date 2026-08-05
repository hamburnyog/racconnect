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
import 'package:racconnect/presentation/widgets/export_all_employees_logs_button.dart';
import 'package:racconnect/presentation/widgets/time_log_bottom_sheet.dart';
import 'package:racconnect/utility/attendance_rules.dart';
import 'package:skeletonizer/skeletonizer.dart';

class TabIndexListener extends StatefulWidget {
  final List<ProfileModel> profiles;
  final Function(ProfileModel) onProfileChanged;
  final Widget child;

  const TabIndexListener({
    super.key,
    required this.profiles,
    required this.onProfileChanged,
    required this.child,
  });

  @override
  State<TabIndexListener> createState() => _TabIndexListenerState();
}

class _TabIndexListenerState extends State<TabIndexListener> {
  TabController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newController = DefaultTabController.of(context);
    if (newController != _controller) {
      _controller?.removeListener(_handleTabChange);
      _controller = newController;
      _controller?.addListener(_handleTabChange);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller != null && _controller!.index < widget.profiles.length) {
          widget.onProfileChanged(widget.profiles[_controller!.index]);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_handleTabChange);
    super.dispose();
  }

  void _handleTabChange() {
    if (_controller != null) {
      final index = _controller!.index;
      if (index >= 0 && index < widget.profiles.length) {
        widget.onProfileChanged(widget.profiles[index]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

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
  ProfileModel? _activeTabProfile;
  String? _selectedEmploymentStatus = 'All';
  String _selectedPeriod = 'Whole Month';
  List<AttendanceModel> _employeeLogs = [];
  List<AttendanceModel> _filteredLogs = [];
  Map<DateTime, String> holidayMap = {};
  Map<DateTime, SuspensionModel> suspensionMap = {};

  bool _isLoadingLogs = false;
  bool _includeWFH = false;
  bool _includeAccomplishment = false;
  final TextEditingController _searchController = TextEditingController();

  List<int> getYears() => List.generate(2, (i) => DateTime.now().year - i);

  ProfileModel? get _effectiveProfile {
    if (_selectedProfile != null) return _selectedProfile;
    final filtered = _getFilteredAndSortedProfiles();
    if (filtered.isEmpty) return null;
    if (_activeTabProfile != null && filtered.contains(_activeTabProfile)) {
      return _activeTabProfile;
    }
    return filtered.first;
  }

  List<ProfileModel> _getFilteredAndSortedProfiles() {
    final list = _profiles.where((p) {
      if (_selectedEmploymentStatus != null && _selectedEmploymentStatus != 'All') {
        return p.employmentStatus == _selectedEmploymentStatus;
      }
      return true;
    }).toList();
    list.sort((a, b) {
      final aNum = a.employeeNumber ?? '';
      final bNum = b.employeeNumber ?? '';
      return aNum.compareTo(bNum);
    });
    return list;
  }

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
        _profiles = profiles.where((p) => p.employmentStatus != 'Resigned').toList();
        final filtered = _getFilteredAndSortedProfiles();
        if (filtered.isNotEmpty) {
          _activeTabProfile = filtered.first;
        }
      });
      _loadEmployeeLogs();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profiles: $e')),
        );
      }
    }
  }

  Future<void> _loadEmployeeLogs() async {
    final profile = _effectiveProfile;
    if (profile == null) {
      setState(() {
        _employeeLogs = [];
        _filteredLogs = [];
      });
      return;
    }
    setState(() => _isLoadingLogs = true);

    final employeeNumber = profile.employeeNumber;
    if (employeeNumber == null) {
      setState(() => _isLoadingLogs = false);
      return;
    }

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
          if (isWFH) return false;
        }

        if (!matchesQuery) return false;

        if (_selectedPeriod == 'First Half') {
          return log.timestamp.day <= 15;
        } else if (_selectedPeriod == 'Second Half') {
          return log.timestamp.day >= 16;
        }

        return true;
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

    if (_effectiveProfile != null) {
      _loadEmployeeLogs();
    }
  }

  void _onEmploymentStatusChanged(String? val) {
    setState(() {
      _selectedEmploymentStatus = val;
      if (_selectedProfile != null && val != 'All' && val != null) {
        if (_selectedProfile!.employmentStatus != val) {
          _selectedProfile = null;
          _employeeLogs = [];
          _filteredLogs = [];
        }
      }
      if (_selectedProfile == null) {
        _activeTabProfile = null;
      }
    });
    _loadEmployeeLogs();
  }

  void _onPeriodChanged(String? val) {
    if (val != null) {
      setState(() {
        _selectedPeriod = val;
        _applyFilter();
      });
    }
  }

  void _onTabProfileChanged(ProfileModel profile) {
    if (_activeTabProfile == profile) return;
    setState(() {
      _activeTabProfile = profile;
    });
    _loadEmployeeLogs();
  }

  void _showLogEditor({DateTime? date, AttendanceModel? log}) {
    final profile = _effectiveProfile;
    if (profile == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => TimeLogBottomSheet(
        log: log,
        initialDate: date,
        employeeNumber: profile.employeeNumber!,
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
    final filteredProfiles = _getFilteredAndSortedProfiles();
    final bool showTabs = _selectedProfile == null && filteredProfiles.isNotEmpty;
    final String profilesKey = filteredProfiles.map((p) => p.employeeNumber ?? '').join(',');

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

                Widget mainContent = Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Stack(
                    children: [
                      Column(
                        children: [
                          _buildHeader(),
                          _buildFilters(),
                          if (showTabs) ...[
                            TabBar(
                              isScrollable: true,
                              tabAlignment: TabAlignment.start,
                              padding: EdgeInsets.zero,
                              labelPadding: const EdgeInsets.symmetric(horizontal: 6.0),
                              labelColor: Colors.deepPurple,
                              unselectedLabelColor: Colors.grey,
                              indicatorColor: Colors.deepPurple,
                              tabs: filteredProfiles.map((p) {
                                final String firstInitial = p.firstName.isNotEmpty ? '${p.firstName[0]}.' : '';
                                return Tab(
                                  child: Text(
                                    '${p.lastName}, $firstInitial (${p.employeeNumber ?? 'N/A'})',
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Expanded(
                            child: showTabs
                                ? TabIndexListener(
                                    profiles: filteredProfiles,
                                    onProfileChanged: _onTabProfileChanged,
                                    child: isSmallScreen ? _buildStackedView() : _buildTwoColumnView(),
                                  )
                                : (isSmallScreen ? _buildStackedView() : _buildTwoColumnView()),
                          ),
                        ],
                      ),
                       Positioned(
                        right: 16,
                        bottom: 16,
                        child: ExportAllEmployeesLogsButton(
                          key: ValueKey('${profilesKey}_${_selectedProfile?.id}_${_selectedPeriod}_$_includeWFH'),
                          selectedYear: selectedYear,
                          selectedMonth: selectedMonth,
                          profiles: filteredProfiles,
                          selectedProfile: _selectedProfile,
                          selectedPeriod: _selectedPeriod,
                          includeWFH: _includeWFH,
                        ),
                      ),
                    ],
                  ),
                );

                if (showTabs) {
                  return DefaultTabController(
                    key: ValueKey(profilesKey),
                    length: filteredProfiles.length,
                    child: mainContent,
                  );
                }
                return mainContent;
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

    final filteredProfilesForDropdown = _profiles.where((p) {
      if (_selectedEmploymentStatus != null && _selectedEmploymentStatus != 'All') {
        return p.employmentStatus == _selectedEmploymentStatus;
      }
      return true;
    }).toList();

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
                      dropdownMenuEntries: filteredProfilesForDropdown.map((p) {
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
                      _loadEmployeeLogs();
                    },
                    icon: const Icon(Icons.close, color: Colors.red),
                    tooltip: 'Clear Selection',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: h,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedEmploymentStatus,
                decoration: decoration.copyWith(labelText: 'Status', labelStyle: const TextStyle(fontSize: 12)),
                items: [
                  const DropdownMenuItem(value: 'All', child: Text('All Statuses', style: TextStyle(fontSize: 13))),
                  ...[
                    'Permanent',
                    'Casual',
                    'Contractual',
                    'Job Order',
                    'COS',
                    'Detailed',
                    'Retired',
                    'OJT',
                  ].map((status) => DropdownMenuItem(value: status, child: Text(status, style: const TextStyle(fontSize: 13)))),
                ],
                onChanged: _onEmploymentStatusChanged,
              ),
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
            SizedBox(
              height: h,
              child: DropdownButtonFormField<String>(
                initialValue: _selectedPeriod,
                decoration: decoration.copyWith(labelText: 'Period', labelStyle: const TextStyle(fontSize: 12)),
                items: [
                  'Whole Month',
                  'First Half',
                  'Second Half',
                ].map((period) => DropdownMenuItem(value: period, child: Text(period, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: _onPeriodChanged,
              ),
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
                    dropdownMenuEntries: filteredProfilesForDropdown.map((p) {
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
                    _loadEmployeeLogs();
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
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    initialValue: _selectedEmploymentStatus,
                    decoration: decoration.copyWith(labelText: 'Status', labelStyle: const TextStyle(fontSize: 12)),
                    items: [
                      const DropdownMenuItem(value: 'All', child: Text('All Statuses', style: TextStyle(fontSize: 13))),
                      ...[
                        'Permanent',
                        'Casual',
                        'Contractual',
                        'Job Order',
                        'COS',
                        'Detailed',
                        'Retired',
                        'OJT',
                      ].map((status) => DropdownMenuItem(value: status, child: Text(status, style: const TextStyle(fontSize: 13)))),
                    ],
                    onChanged: _onEmploymentStatusChanged,
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
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: h,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedPeriod,
                    decoration: decoration.copyWith(labelText: 'Period', labelStyle: const TextStyle(fontSize: 12)),
                    items: [
                      'Whole Month',
                      'First Half',
                      'Second Half',
                    ].map((period) => DropdownMenuItem(value: period, child: Text(period, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: _onPeriodChanged,
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
      child: _effectiveProfile == null
          ? _buildEmptyState('Select an employee to view DTR', 'assets/images/dog.png')
          : _buildDtrTable(),
    );

    return Card(
      color: Colors.white,
      child: Column(
        mainAxisSize: isSmallScreen ? MainAxisSize.min : MainAxisSize.max,
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_view_month),
            title: const Text('DTR View', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: _effectiveProfile != null
                ? Text(
                    '${_effectiveProfile!.lastName}, ${_effectiveProfile!.firstName} (${_effectiveProfile!.employeeNumber ?? 'N/A'})',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  )
                : null,
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
      child: _effectiveProfile == null
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
          ListTile(
            leading: const Icon(Icons.list_alt),
            title: const Text('Raw Logs', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: _effectiveProfile != null
                ? Text(
                    '${_effectiveProfile!.lastName}, ${_effectiveProfile!.firstName} (${_effectiveProfile!.employeeNumber ?? 'N/A'})',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  )
                : null,
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
    final days = _getDaysForPeriod(selectedYear, selectedMonth);

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
    if (day.weekday == DateTime.saturday || day.weekday == DateTime.sunday) {
      return false;
    }

    final dateKey = DateTime(day.year, day.month, day.day);
    if (holidayMap.containsKey(dateKey)) {
      return false;
    }

    if (suspensionMap.containsKey(dateKey)) {
      return false;
    }

    return true;
  }

  List<DateTime> _getDaysInMonth(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0);
    return List.generate(lastDay.day, (i) => DateTime(year, month, i + 1));
  }

  List<DateTime> _getDaysForPeriod(int year, int month) {
    final allDays = _getDaysInMonth(year, month);
    if (_selectedPeriod == 'First Half') {
      return allDays.where((d) => d.day <= 15).toList();
    } else if (_selectedPeriod == 'Second Half') {
      return allDays.where((d) => d.day >= 16).toList();
    }
    return allDays;
  }
}
