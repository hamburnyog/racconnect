import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';
import 'package:racconnect/logic/cubit/event_cubit.dart';
import 'package:racconnect/logic/cubit/suspension_cubit.dart';
import 'package:racconnect/presentation/widgets/attendance_form.dart';
import 'package:racconnect/presentation/widgets/clock_in_button.dart';
import 'package:table_calendar/table_calendar.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DateTime now = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _lockClockIn = true;

  Map<String, List> mySelectedEvents = {};

  @override
  void initState() {
    super.initState();
    checkProfile();
    _selectedDay = _focusedDay;
    loadEvents();
  }

  void _showAttendanceForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      scrollControlDisabledMaxHeightRatio: 0.75,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext builder) {
        return AttendanceForm();
      },
    );
  }

  @override
  void dispose() {
    _focusedDay = DateTime.now();
    _selectedDay = null;
    mySelectedEvents.clear();
    super.dispose();
  }

  Future<void> checkProfile() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthenticatedState) {
      var profile = authState.user.profile;
      var employeeNumber = profile?.employeeNumber ?? '';

      if (employeeNumber.isNotEmpty) {
        setState(() {
          _lockClockIn = false;
        });
      } else {
        setState(() {
          _lockClockIn = true;
        });
      }
    }
  }

  Future<void> loadEvents() async {
    final eventCubit = context.read<EventCubit>();
    final suspensionCubit = context.read<SuspensionCubit>();

    await eventCubit.getAllEvents();
    final eventState = eventCubit.state;

    await suspensionCubit.getAllSuspensions();
    final suspensionState = suspensionCubit.state;

    if (!mounted) return;

    if (eventState is GetAllEventSuccess) {
      setState(() {
        mySelectedEvents = Map<String, List>.from(eventState.events);
      });
    }

    if (suspensionState is GetAllSuspensionSuccess) {
      setState(() {
        for (var suspension in suspensionState.suspensionModels) {
          final dateKey = DateFormat('yyyy-MM-dd').format(suspension.datetime);
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: [
                Card(
                  color: Theme.of(context).primaryColor,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDay = now;
                        _focusedDay = now;
                      });
                    },
                    child: ListTile(
                      leading: Icon(Icons.home, color: Colors.white),
                      minTileHeight: 70,
                      title: Text(
                        (isSmallScreen)
                            ? DateFormat.yMMMMd().format(now)
                            : 'Today is ${DateFormat.yMMMMd().format(now)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        listOfDayEvents(_selectedDay!).isNotEmpty
                            ? '${listOfDayEvents(_selectedDay!).length} event${listOfDayEvents(_selectedDay!).length > 1 ? 's' : ''} for ${DateFormat.yMMMMd().format(_selectedDay!)}'
                            : (_selectedDay == null ||
                                (_selectedDay!.year == now.year &&
                                    _selectedDay!.month == now.month &&
                                    _selectedDay!.day == now.day))
                            ? 'No event for today'
                            : 'No event for the selected day',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      trailing: ClockInButton(
                        lockClockIn: _lockClockIn,
                        onPressed: _showAttendanceForm,
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: BlocBuilder<EventCubit, EventState>(
                    builder: (context, state) {
                      if (state is EventLoading) {
                        return Column(
                          children: [
                            SizedBox(height: 30),
                            CircularProgressIndicator(),
                          ],
                        );
                      }

                      if (state is EventError) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.error),
                              backgroundColor: Colors.red,
                            ),
                          );
                        });
                      }

                      if (state is GetAllEventSuccess &&
                          listOfDayEvents(_selectedDay!).isNotEmpty) {
                        return Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Wrap(
                                alignment: WrapAlignment.start,
                                spacing: 8.0,
                                runSpacing: 8.0,
                                children:
                                    listOfDayEvents(_selectedDay!).map<Widget>((
                                      myEvent,
                                    ) {
                                      final parts = myEvent.toString().split(
                                        ',T=',
                                      );
                                      final title = parts[0];
                                      final type =
                                          parts.length > 1
                                              ? parts[1]
                                              : 'Unknown';

                                      return Chip(
                                        avatar: CircleAvatar(
                                          backgroundColor: Colors.grey.shade200,
                                          child: Icon(
                                            () {
                                              switch (type) {
                                                case 'Holiday':
                                                  return Icons.event;
                                                case 'Birthday':
                                                  return Icons.cake;
                                                case 'Suspension':
                                                  return Icons.flood;
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
                                                  return Colors.orange;
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
                                            fontWeight: FontWeight.bold,
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
                      return SizedBox.shrink();
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
                      firstDay: now.subtract(const Duration(days: 365)),
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
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          return Center(
                            child: Text(
                              text.toUpperCase(),
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          );
                        },
                        markerBuilder: (context, date, events) {
                          if (events.isEmpty) return null;
                          return Positioned(
                            bottom: isSmallScreen ? 2 : 5,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children:
                                  events.map((event) {
                                    final parts = event.toString().split(',T=');
                                    final type =
                                        parts.length > 1 ? parts[1] : 'Unknown';
                                    return Container(
                                      margin: const EdgeInsets.symmetric(
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
