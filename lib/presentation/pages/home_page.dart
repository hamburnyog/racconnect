import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';
import 'package:racconnect/logic/cubit/event_cubit.dart';
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
    AuthSignedIn signedIn = context.read<AuthCubit>().state as AuthSignedIn;
    var profile = signedIn.user.profile;
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

  Future<void> loadEvents() async {
    var cubit = context.read<EventCubit>();
    await cubit.getAllEvents();
    final state = cubit.state;
    if (state is GetAllEventSuccess) {
      setState(() {
        mySelectedEvents = Map<String, List>.from(state.events);
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
                        'Today is ${DateFormat.yMMMMd().format(now)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        listOfDayEvents(_selectedDay!).isNotEmpty
                            ? '${listOfDayEvents(_selectedDay!).length} event${listOfDayEvents(_selectedDay!).length > 1 ? 's' : ''} for ${DateFormat.yMMMMd().format(_selectedDay!)}'
                            : 'No event for the selected day',
                        style: TextStyle(color: Colors.white),
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
                                      final type = parts[1];

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
                                                default:
                                                  return Icons.event;
                                              }
                                            }(),
                                            color: () {
                                              switch (type) {
                                                case 'Holiday':
                                                  return Theme.of(
                                                    context,
                                                  ).primaryColor;
                                                case 'Birthday':
                                                  return Colors.red;
                                                default:
                                                  return Colors.green;
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
                      startingDayOfWeek: StartingDayOfWeek.monday,
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
