import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/travel_model.dart';
import 'package:racconnect/data/models/user_model.dart';
import 'package:racconnect/data/repositories/auth_repository.dart';
import 'package:racconnect/logic/cubit/travel_cubit.dart';
import 'package:racconnect/presentation/widgets/mobile_button.dart';
import 'package:racconnect/presentation/widgets/travel_form.dart';

class TravelPage extends StatefulWidget {
  const TravelPage({super.key});

  @override
  State<TravelPage> createState() => _TravelPageState();
}

class _TravelPageState extends State<TravelPage> {
  OverlayEntry? _overlayEntry;
  final ScrollController _scrollController = ScrollController();
  List<UserModel> _allUsers = [];

  void _showTravelForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      scrollControlDisabledMaxHeightRatio: 0.9,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext builder) {
        return const TravelForm();
      },
    );
  }

  void _showTravelFormWithEdit(TravelModel travelModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      scrollControlDisabledMaxHeightRatio: 0.9,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext builder) {
        return TravelForm(travelModel: travelModel);
      },
    );
  }

  void _deleteTravel(String id) {
    context.read<TravelCubit>().deleteTravel(id: id);
  }

  List<String> _getEmployeeNames(List<String> employeeNumbers) {
    final names = <String>[];
    for (final employeeNumber in employeeNumbers) {
      try {
        final user = _allUsers.firstWhere(
          (user) => user.profile?.employeeNumber == employeeNumber,
        );
        if (user.profile != null) {
          names.add('${user.profile!.lastName}, ${user.profile!.firstName}');
        } else {
          names.add('Unknown Employee');
        }
      } catch (e) {
        names.add('Unknown Employee');
      }
    }
    return names;
  }

  String _formatTravelDates(List<DateTime> dates) {
    if (dates.isEmpty) return 'No dates';

    // Sort dates
    dates.sort((a, b) => a.compareTo(b));

    if (dates.length == 1) {
      return DateFormat('MMM d, yyyy').format(dates.first);
    } else {
      return '${DateFormat('MMM d, yyyy').format(dates.first)} - ${DateFormat('MMM d, yyyy').format(dates.last)}';
    }
  }

  String _createTooltipMessage(TravelModel travelModel) {
    final employeeNames = _getEmployeeNames(travelModel.employeeNumbers);
    final buffer = StringBuffer();

    buffer.writeln('Staff:');
    for (final name in employeeNames) {
      buffer.writeln('  • $name');
    }

    if (travelModel.specificDates.isNotEmpty) {
      buffer.writeln('Dates:');
      final sortedDates = List<DateTime>.from(travelModel.specificDates)
        ..sort((a, b) => a.compareTo(b));
      for (final date in sortedDates) {
        buffer.writeln('  • ${DateFormat('MMM d, yyyy').format(date)}');
      }
    }

    return buffer.toString();
  }

  void _showTooltip(
    BuildContext context,
    Offset position,
    Size size,
    TravelModel travelModel,
  ) {
    _removeTooltip();
    final overlay = Overlay.of(context);
    final tooltip = _createTooltipMessage(travelModel);

    final tooltipWidth = 200.0;
    final screenWidth = MediaQuery.of(context).size.width;

    var left = position.dx + 5;
    if (left + tooltipWidth > screenWidth) {
      left = screenWidth - tooltipWidth;
    }
    if (left < 0) {
      left = 0;
    }

    final top = (position.dy + size.height) + 5;

    _overlayEntry = OverlayEntry(
      builder:
          (context) => Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onTap: () {
                    _removeTooltip();
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
              Positioned(
                left: left,
                top: top,
                child: Material(
                  elevation: 4.0,
                  borderRadius: BorderRadius.circular(8.0),
                  child: Container(
                    width: tooltipWidth,
                    padding: const EdgeInsets.only(top: 8.0, left: 8, right: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      tooltip,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
            ],
          ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _removeTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void initState() {
    super.initState();
    _loadUsers();
    context.read<TravelCubit>().getAllTravels();
  }

  Future<void> _loadUsers() async {
    try {
      final authRepository = AuthRepository();
      final users = await authRepository.getUsers();
      setState(() {
        _allUsers = users;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading employees: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _removeTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isSmallScreen = width < 700;

    return RefreshIndicator(
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      onRefresh: () async {
        context.read<TravelCubit>().getAllTravels();
      },
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Column(
            children: [
              Card(
                color: Theme.of(context).primaryColor,
                child: ListTile(
                  minTileHeight: 70,
                  title: const Text(
                    'Travel',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    !isSmallScreen
                        ? 'Manage travel orders here. Pull down to refresh, or swipe left on a record to delete.'
                        : 'Manage travel orders here',
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                  leading: const Icon(
                    Icons.airplane_ticket,
                    color: Colors.white,
                  ),
                  trailing: MobileButton(
                    isSmallScreen: isSmallScreen,
                    onPressed: _showTravelForm,
                    icon: const Icon(Icons.add),
                    label: 'Add',
                  ),
                ),
              ),
              BlocBuilder<TravelCubit, TravelState>(
                builder: (context, state) {
                  var travels = [];
                  if (state is TravelLoading) {
                    return const Column(
                      children: [
                        SizedBox(height: 30),
                        CircularProgressIndicator(),
                      ],
                    );
                  }

                  if (state is TravelError) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.error),
                          backgroundColor: Colors.red,
                        ),
                      );
                    });
                  }

                  if (state is TravelError ||
                      state is TravelAddSuccess ||
                      state is TravelUpdateSuccess ||
                      state is TravelDeleteSuccess) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      context.read<TravelCubit>().getAllTravels();
                    });
                  }

                  if (state is GetAllTravelSuccess) {
                    travels = state.travelModels.toList();

                    if (travels.isNotEmpty) {
                      return Expanded(
                        child: Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          interactive: true,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            scrollDirection: Axis.vertical,
                            controller: _scrollController,
                            itemCount: travels.length,
                            itemBuilder: (context, index) {
                              final travelModel = travels[index];
                              return ClipRect(
                                child: Dismissible(
                                  key: Key(travelModel.id!),
                                  direction: DismissDirection.endToStart,
                                  onDismissed: (direction) async {},
                                  confirmDismiss: (
                                    DismissDirection direction,
                                  ) async {
                                    return await showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text("Confirm"),
                                          content: const Text(
                                            "Are you sure you want to delete this travel order?",
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.of(
                                                    context,
                                                  ).pop(false),
                                              child: const Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                _deleteTravel(travelModel.id!);
                                                Navigator.of(context).pop(true);
                                              },
                                              child: const Text("Delete"),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  background: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.pink,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.centerRight,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                    ),
                                    child: const Icon(
                                      Icons.delete,
                                      color: Colors.white,
                                    ),
                                  ),
                                  child: Builder(
                                    builder: (context) {
                                      return GestureDetector(
                                        onTapUp: (details) {
                                          final RenderBox renderBox =
                                              context.findRenderObject()
                                                  as RenderBox;
                                          final size = renderBox.size;
                                          final position = renderBox
                                              .localToGlobal(Offset.zero);
                                          _showTooltip(
                                            context,
                                            position,
                                            size,
                                            travelModel,
                                          );
                                        },
                                        child: Card(
                                          elevation: 3,
                                          child: ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor:
                                                  Theme.of(
                                                    context,
                                                  ).primaryColor,
                                              child: const Icon(
                                                Icons.directions_car,
                                                color: Colors.white,
                                              ),
                                            ),
                                            title: Text(
                                              travelModel.soNumber,
                                              style: TextStyle(
                                                fontSize: 16,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).primaryColor,
                                              ),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '${travelModel.employeeNumbers.length} employee${travelModel.employeeNumbers.length != 1 ? 's' : ''}, ${travelModel.specificDates.length} date${travelModel.specificDates.length != 1 ? 's' : ''}',
                                                  style: const TextStyle(
                                                    fontSize: 10,
                                                  ),
                                                ),
                                                if (travelModel
                                                    .specificDates
                                                    .isNotEmpty)
                                                  Text(
                                                    _formatTravelDates(
                                                      travelModel.specificDates,
                                                    ),
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            trailing: GestureDetector(
                                              onTap: () {
                                                _showTravelFormWithEdit(
                                                  travelModel,
                                                );
                                              },
                                              child: Icon(
                                                Icons.edit_note,
                                                color:
                                                    Theme.of(
                                                      context,
                                                    ).primaryColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }
                  }
                  return Expanded(
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 50),
                        SvgPicture.asset('assets/images/dog.svg', height: 100),
                        const Center(
                          child: Text(
                            'Nothing is here yet. Add a travel order to get started.',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
