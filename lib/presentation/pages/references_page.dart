import 'package:flutter/material.dart';
import 'package:racconnect/presentation/pages/holiday_page.dart';
import 'package:racconnect/presentation/pages/leave_page.dart';
import 'package:racconnect/presentation/pages/section_page.dart';
import 'package:racconnect/presentation/pages/signatory_page.dart';
import 'package:racconnect/presentation/pages/suspension_page.dart';
import 'package:racconnect/presentation/pages/travel_page.dart';
import 'package:racconnect/presentation/widgets/holiday_form.dart';
import 'package:racconnect/presentation/widgets/section_form.dart';
import 'package:racconnect/presentation/widgets/signatory_form.dart';
import 'package:racconnect/presentation/widgets/suspension_form.dart';
import 'package:racconnect/presentation/widgets/travel_form.dart';
import 'package:racconnect/presentation/widgets/leave_form.dart';

class ReferencesPage extends StatefulWidget {
  final String role;
  const ReferencesPage({super.key, required this.role});

  @override
  State<ReferencesPage> createState() => _ReferencesPageState();
}

class _ReferencesPageState extends State<ReferencesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<(Widget, Tab, String)> _tabs = [];
  bool _showLeftIndicator = false;
  bool _showRightIndicator = false;

  @override
  void initState() {
    super.initState();
    _buildTabs();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });

    // Initial check for scrollability after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateIndicators();
    });
  }

  void _updateIndicators() {
    // This is a bit tricky with TabBar as it doesn't expose its scroll controller.
    // However, the NotificationListener will handle updates once scrolling starts.
    // For the initial state, we assume if there are more than 3 tabs on a small screen, 
    // there's likely more to the right.
    if (mounted) {
      final width = MediaQuery.of(context).size.width;
      if (width < 600 && _tabs.length > 3) {
        setState(() {
          _showRightIndicator = true;
        });
      }
    }
  }

  void _buildTabs() {
    final role = widget.role;
    if (role == 'Developer') {
      _tabs.add((
        const SectionPage(),
        const Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.group_outlined, size: 18),
              SizedBox(width: 8),
              Text('Sections'),
            ],
          ),
        ),
        'Sections'
      ));
    }

    if (role == 'Developer' || role == 'HR' || role == 'Unit Head') {
      _tabs.add((
        const SignatoryPage(),
        const Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.assignment_ind_outlined, size: 18),
              SizedBox(width: 8),
              Text('Signatories'),
            ],
          ),
        ),
        'Signatories'
      ));
    }

    if (role == 'Developer' || role == 'HR') {
      _tabs.add((
        const HolidayPage(),
        const Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_month_outlined, size: 18),
              SizedBox(width: 8),
              Text('Holidays'),
            ],
          ),
        ),
        'Holidays'
      ));
      _tabs.add((
        const SuspensionPage(),
        const Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flood_outlined, size: 18),
              SizedBox(width: 8),
              Text('Suspensions'),
            ],
          ),
        ),
        'Suspensions'
      ));
    }

    if (role == 'Developer' || role == 'Records' || role == 'Record') {
      _tabs.add((
        const TravelPage(),
        const Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.directions_car, size: 18),
              SizedBox(width: 8),
              Text('Travels'),
            ],
          ),
        ),
        'Travels'
      ));
    }

    if (role == 'Developer' || role == 'HR') {
      _tabs.add((
        const LeavePage(),
        const Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sick_outlined, size: 18),
              SizedBox(width: 8),
              Text('Leaves'),
            ],
          ),
        ),
        'Leaves'
      ));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onFabPressed() {
    final activeTabLabel = _tabs[_tabController.index].$3;
    Widget? form;

    switch (activeTabLabel) {
      case 'Sections':
        form = const SectionForm();
        break;
      case 'Signatories':
        form = const SignatoryForm();
        break;
      case 'Holidays':
        form = const HolidayForm();
        break;
      case 'Suspensions':
        form = const SuspensionForm();
        break;
      case 'Travels':
        form = const TravelForm();
        break;
      case 'Leaves':
        form = const LeaveForm();
        break;
    }

    if (form != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        scrollControlDisabledMaxHeightRatio: 0.75,
        showDragHandle: true,
        useSafeArea: true,
        builder: (BuildContext builder) {
          return form!;
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_tabs.isEmpty) {
      return const Center(child: Text('No references available'));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Stack(
            children: [
              NotificationListener<ScrollNotification>(
                onNotification: (ScrollNotification notification) {
                  if (notification is ScrollUpdateNotification) {
                    setState(() {
                      _showLeftIndicator = notification.metrics.pixels > 5;
                      _showRightIndicator = notification.metrics.pixels <
                          notification.metrics.maxScrollExtent - 5;
                    });
                  }
                  return false;
                },
                child: Material(
                  color: Colors.transparent,
                  child: TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Theme.of(context).primaryColor,
                    tabs: _tabs.map((t) => t.$2).toList(),
                  ),
                ),
              ),
              if (_showLeftIndicator)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.grey[200]!,
                            Colors.grey[200]!.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                      child: const Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(Icons.chevron_left,
                            size: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              if (_showRightIndicator)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: Container(
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerRight,
                          end: Alignment.centerLeft,
                          colors: [
                            Colors.grey[200]!,
                            Colors.grey[200]!.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                      child: const Align(
                        alignment: Alignment.centerRight,
                        child: Icon(Icons.chevron_right,
                            size: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((t) => t.$1).toList(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabPressed,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
