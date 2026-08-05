import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/blocs/cubit/auth_cubit.dart';
import 'package:racconnect/data/blocs/cubit/event_cubit.dart';
import 'package:racconnect/data/blocs/cubit/leave_cubit.dart';
import 'package:racconnect/data/blocs/cubit/suspension_cubit.dart';
import 'package:racconnect/data/blocs/cubit/travel_cubit.dart';
import 'package:racconnect/utility/constants.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  final Function(int) onNavigate;
  const HomePage({super.key, required this.onNavigate});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DateTime now = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;

  Map<String, List> mySelectedEvents = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await loadEvents();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _focusedDay = DateTime.now();
    _selectedDay = null;
    mySelectedEvents.clear();
    super.dispose();
  }

  Future<void> loadEvents() async {
    final eventCubit = context.read<EventCubit>();
    final suspensionCubit = context.read<SuspensionCubit>();
    final leaveCubit = context.read<LeaveCubit>();
    final travelCubit = context.read<TravelCubit>();

    final authState = context.read<AuthCubit>().state;
    String employeeNumber = '';
    if (authState is AuthenticatedState) {
      employeeNumber = authState.user.profile?.employeeNumber ?? '';
    }

    await eventCubit.getAllEvents();
    final eventState = eventCubit.state;

    await suspensionCubit.getAllSuspensions();
    final suspensionState = suspensionCubit.state;

    if (employeeNumber.isNotEmpty) {
      await leaveCubit.getAllLeaves();
    }
    final leaveState = leaveCubit.state;

    if (employeeNumber.isNotEmpty) {
      await travelCubit.getAllTravels();
    }
    final travelState = travelCubit.state;

    if (!mounted) return;

    if (eventState is GetAllEventSuccess) {
      if (mounted) {
        setState(() {
          mySelectedEvents = Map<String, List>.from(eventState.events);
        });
      }
    }

    if (suspensionState is GetAllSuspensionSuccess) {
      if (mounted) {
        setState(() {
          for (var suspension in suspensionState.suspensionModels) {
            final dateKey = DateFormat(
              'yyyy-MM-dd',
            ).format(suspension.datetime);
            final time = DateFormat('hh:mm a').format(suspension.datetime);
            final title =
                suspension.isHalfday
                    ? '${suspension.name} ($time)'
                    : suspension.name;
            final eventString = '$title,T=Suspension';

            if (mySelectedEvents.containsKey(dateKey)) {
              mySelectedEvents[dateKey]!.add(eventString);
            } else {
              mySelectedEvents[dateKey] = [eventString];
            }
          }
        });
      }
    }

    if (leaveState is GetAllLeaveSuccess && employeeNumber.isNotEmpty) {
      if (mounted) {
        setState(() {
          for (var leave in leaveState.leaveModels) {
            if (leave.employeeNumbers.contains(employeeNumber)) {
              for (var date in leave.specificDates) {
                final dateKey = DateFormat('yyyy-MM-dd').format(date);
                final eventString = '${leave.type},T=Leave';

                if (mySelectedEvents.containsKey(dateKey)) {
                  mySelectedEvents[dateKey]!.add(eventString);
                } else {
                  mySelectedEvents[dateKey] = [eventString];
                }
              }
            }
          }
        });
      }
    }

    if (travelState is GetAllTravelSuccess && employeeNumber.isNotEmpty) {
      if (mounted) {
        setState(() {
          for (var travel in travelState.travelModels) {
            if (travel.employeeNumbers.contains(employeeNumber)) {
              for (var date in travel.specificDates) {
                final dateKey = DateFormat('yyyy-MM-dd').format(date);
                final eventString = '${travel.soNumber},T=Travel';

                if (mySelectedEvents.containsKey(dateKey)) {
                  mySelectedEvents[dateKey]!.add(eventString);
                } else {
                  mySelectedEvents[dateKey] = [eventString];
                }
              }
            }
          }
        });
      }
    }
  }

  List listOfDayEvents(DateTime dateTime) {
    if (mySelectedEvents[DateFormat(
          'yyyy-MM-dd',
        ).format(dateTime).toString()] !=
        null) {
      return mySelectedEvents[DateFormat(
        'yyyy-MM-dd',
      ).format(dateTime).toString()]!;
    } else {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isSmallScreen = width < 700;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is! AuthenticatedState) {
          return const Center(child: CircularProgressIndicator());
        }

        final user = state.user;
        final role = user.role ?? '';

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Skeletonizer(
                enabled: _isLoading,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          _buildQuickAccessGrid(context, role),
                          const SizedBox(height: 16),
                          Card(
                            color: Theme.of(context).primaryColor,
                            child: ListTile(
                              leading: const Icon(
                                Icons.calendar_month,
                                color: Colors.white,
                              ),
                              minTileHeight: 70,
                              title: Text(
                                DateFormat.yMMMMd().format(_selectedDay ?? now),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                listOfDayEvents(_selectedDay ?? now).isNotEmpty
                                    ? '${listOfDayEvents(_selectedDay ?? now).length} event${listOfDayEvents(_selectedDay ?? now).length > 1 ? 's' : ''} for ${DateFormat.yMMMMd().format(_selectedDay ?? now)}'
                                    : 'No event for the selected day',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: BlocBuilder<EventCubit, EventState>(
                              builder: (context, eventState) {
                                if (eventState is EventLoading) {
                                  return const Column(
                                    children: [
                                      SizedBox(height: 30),
                                      CircularProgressIndicator(),
                                    ],
                                  );
                                }

                                if (eventState is EventError) {
                                  return Center(
                                    child: Text(
                                      eventState.error,
                                      style: const TextStyle(color: Colors.red),
                                    ),
                                  );
                                }

                                if (listOfDayEvents(_selectedDay ?? now)
                                    .isNotEmpty) {
                                  return Column(
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Wrap(
                                          alignment: WrapAlignment.start,
                                          spacing: 8.0,
                                          runSpacing: 8.0,
                                          children:
                                              listOfDayEvents(
                                                _selectedDay ?? now,
                                              ).map<Widget>((myEvent) {
                                                final parts = myEvent
                                                    .toString()
                                                    .split(',T=');
                                                final title = parts[0];
                                                final type =
                                                    parts.length > 1
                                                        ? parts[1]
                                                        : 'Unknown';

                                                return Chip(
                                                  avatar: CircleAvatar(
                                                    backgroundColor:
                                                        Colors.grey.shade200,
                                                    child: Icon(
                                                      () {
                                                        switch (type) {
                                                          case 'Holiday':
                                                            return Icons.event;
                                                          case 'Birthday':
                                                            return Icons.cake;
                                                          case 'Suspension':
                                                            return Icons.flood;
                                                          case 'Leave':
                                                            return Icons.sick;
                                                          case 'Travel':
                                                            return Icons
                                                                .directions_car;
                                                          default:
                                                            return Icons.event;
                                                        }
                                                      }(),
                                                      color: () {
                                                        switch (type) {
                                                          case 'Holiday':
                                                            return Colors.green;
                                                          case 'Birthday':
                                                            return Colors.red;
                                                          case 'Suspension':
                                                            return Colors
                                                                .orange;
                                                          case 'Leave':
                                                            return Colors
                                                                .purple;
                                                          case 'Travel':
                                                            return Colors.teal;
                                                          default:
                                                            return Colors.grey;
                                                        }
                                                      }(),
                                                      size: 18,
                                                    ),
                                                  ),
                                                  label: Text(
                                                    title,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                        ),
                                      ),
                                    ],
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TableCalendar(
                                headerStyle: const HeaderStyle(
                                  formatButtonVisible: false,
                                  titleCentered: true,
                                ),
                                rowHeight: isSmallScreen ? 40 : 60,
                                startingDayOfWeek: StartingDayOfWeek.sunday,
                                availableGestures: AvailableGestures.none,
                                firstDay: now.subtract(
                                  const Duration(days: 365),
                                ),
                                lastDay: now.add(const Duration(days: 365)),
                                focusedDay: _focusedDay,
                                selectedDayPredicate: (day) {
                                  return isSameDay(_selectedDay, day);
                                },
                                onDaySelected: (selectedDay, focusedDay) {
                                  if (!isSameDay(_selectedDay, selectedDay)) {
                                    setState(() {
                                      _selectedDay = selectedDay;
                                      _focusedDay = focusedDay;
                                    });
                                  }
                                },
                                onPageChanged: (focusedDay) {
                                  _focusedDay = focusedDay;
                                },
                                eventLoader: listOfDayEvents,
                                calendarBuilders: CalendarBuilders(
                                  dowBuilder: (context, day) {
                                    final text = DateFormat.E().format(day);
                                    if (day.weekday == DateTime.sunday ||
                                        day.weekday == DateTime.saturday) {
                                      return Center(
                                        child: Text(
                                          text.toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    }
                                    return Center(
                                      child: Text(
                                        text.toUpperCase(),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                  markerBuilder: (context, date, events) {
                                    if (events.isEmpty) return null;
                                    return Positioned(
                                      bottom: isSmallScreen ? 2 : 5,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children:
                                            events.map((event) {
                                              final parts = event
                                                  .toString()
                                                  .split(',T=');
                                              final type =
                                                  parts.length > 1
                                                      ? parts[1]
                                                      : 'Unknown';
                                              return Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 1.5,
                                                    ),
                                                width: isSmallScreen ? 6 : 8,
                                                height: isSmallScreen ? 6 : 8,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: () {
                                                    switch (type) {
                                                      case 'Birthday':
                                                        return Colors.red;
                                                      case 'Holiday':
                                                        return Colors.green;
                                                      case 'Suspension':
                                                        return Colors.orange;
                                                      case 'Leave':
                                                        return Colors.purple;
                                                      case 'Travel':
                                                        return Colors.teal;
                                                      default:
                                                        return Colors.grey;
                                                    }
                                                  }(),
                                                ),
                                              );
                                            }).toList(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (role.isNotEmpty)
              Positioned(
                right: 10,
                bottom: 10,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingActionButton(
                      mini: true,
                      heroTag: 'orgChartFab',
                      backgroundColor: Colors.white,
                      onPressed: () {
                        launchUrl(Uri.parse(canvaDesignUrl));
                      },
                      child: Icon(
                        Icons.account_tree,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FloatingActionButton(
                      mini: true,
                      heroTag: 'uniformFab',
                      backgroundColor: Colors.white,
                      onPressed: () {
                        final gender = user.profile?.gender ?? '';
                        showDialog(
                          context: context,
                          builder:
                              (context) => Dialog(
                                backgroundColor: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12.0,
                                            vertical: 6.0,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                Theme.of(context).primaryColor,
                                            borderRadius: BorderRadius.circular(
                                              20.0,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.checkroom,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'RACCO IV-A Calabarzon Dress Code'
                                                    .toUpperCase(),
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (gender.toLowerCase() == 'male')
                                          Image.asset(
                                            'assets/images/boys-uniform-nobg.png',
                                          )
                                        else
                                          Image.asset(
                                            'assets/images/girls-uniform-nobg.png',
                                          ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8.0,
                                          ),
                                          child: const Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'First Working Day of Month:',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              Text(
                                                'ASEAN-Inspired',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              Text(
                                                'Monday: Barong/Filipiniana',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              Text(
                                                'Other Weekdays: At Least Smart Casual',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              Text(
                                                '(Tue: White, Wed: Black, Thu: Gray, Friday: Any Color)',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.black,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                        );
                      },
                      child: Icon(
                        Icons.checkroom,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildQuickAccessGrid(BuildContext context, String role) {
    final bool canSeePersonnel = [
      'Developer',
      'OIC',
      'HR',
      'Unit Head',
    ].contains(role);
    final bool canSeeReferences = [
      'Developer',
      'HR',
      'Records',
      'Record',
      'Unit Head',
    ].contains(role);

    final bool isSmallScreen = MediaQuery.of(context).size.width < 700;

    final List<Widget> cards = [
      _buildMenuCard(
        context,
        title: 'Attendance',
        subtitle: isSmallScreen ? null : 'WFH, DTR, Accomplishment Reports',
        icon: Icons.access_time_filled,
        color: Colors.orangeAccent,
        onTap: () => widget.onNavigate(1),
      ),
      if (role.isNotEmpty)
        _buildMenuCard(
          context,
          title: 'Certificates',
          subtitle: isSmallScreen ? null : 'Manage Forum Certificates',
          icon: Icons.card_membership_rounded,
          color: Colors.purpleAccent,
          onTap: () => widget.onNavigate(2),
        ),
      if (canSeePersonnel)
        _buildMenuCard(
          context,
          title: 'Personnel',
          subtitle: isSmallScreen ? null : 'View of your Staff Details',
          icon: Icons.badge,
          color: Colors.greenAccent[700]!,
          onTap: () {
            widget.onNavigate(3);
          },
        ),
      if (canSeeReferences)
        _buildMenuCard(
          context,
          title: 'References',
          subtitle: isSmallScreen ? null : 'Manage system references',
          icon: Icons.library_books,
          color: Colors.tealAccent[700]!,
          onTap: () {
            if (role == 'Developer') {
              widget.onNavigate(5);
            } else if (role == 'HR' || role == 'Unit Head') {
              widget.onNavigate(4);
            } else if (role == 'Records' || role == 'Record') {
              widget.onNavigate(3);
            }
          },
        ),
      if (role == 'Developer')
        _buildMenuCard(
          context,
          title: 'Office Logs',
          subtitle: isSmallScreen ? null : 'Prepare Biometric Records for HRMIS',
          icon: Icons.fingerprint,
          color: Colors.blueAccent,
          onTap: () => widget.onNavigate(4),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        int crossAxisCount = 2;
        double childAspectRatio = isSmallScreen ? 2.5 : 3.5;

        if (width > 1200) {
          crossAxisCount = 4;
          childAspectRatio = 4.0;
        } else if (width > 800) {
          crossAxisCount = 3;
          childAspectRatio = 3.8;
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: childAspectRatio,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) => cards[index],
          ),
        );
      },
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    String? subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withValues(alpha: 0.1),
          highlightColor: color.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
