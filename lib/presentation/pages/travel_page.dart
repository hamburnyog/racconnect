import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/travel_model.dart';
import 'package:racconnect/logic/cubit/travel_cubit.dart';
import 'package:racconnect/presentation/widgets/mobile_button.dart';
import 'package:racconnect/presentation/widgets/travel_form.dart';
import 'package:skeletonizer/skeletonizer.dart';

class TravelPage extends StatefulWidget {
  const TravelPage({super.key});

  @override
  State<TravelPage> createState() => _TravelPageState();
}

class _TravelPageState extends State<TravelPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;

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

  @override
  void initState() {
    super.initState();
    _loadTravels();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _loadTravels() async {
    setState(() {
      _isLoading = true;
    });
    await context.read<TravelCubit>().getAllTravels();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isSmallScreen = width < 700;

    return RefreshIndicator(
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      onRefresh: _loadTravels,
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
          child: Skeletonizer(
            enabled: _isLoading,
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
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                    leading: const Icon(
                      Icons.directions_car,
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 3.0,
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by SO number or travel date',
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).primaryColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                BlocConsumer<TravelCubit, TravelState>(
                  listener: (context, state) {
                    if (state is TravelError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.error),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else if (state is TravelAddSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Travel added successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadTravels();
                    } else if (state is TravelUpdateSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Travel updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadTravels();
                    } else if (state is TravelDeleteSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Travel deleted successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadTravels();
                    }
                  },
                  builder: (context, state) {
                    if (state is GetAllTravelSuccess) {
                      final travels = state.travelModels.toList();
                      
                      // Apply search filter
                      if (_searchQuery.isNotEmpty) {
                        travels.retainWhere((travel) {
                          final soNumber = travel.soNumber.toLowerCase();
                          final employeeNumbers = travel.employeeNumbers.join(' ').toLowerCase();
                          final travelDates = travel.specificDates.map((date) => 
                              DateFormat('MMMM d, yyyy').format(date).toLowerCase()
                            ).join(' ');
                          final travelDatesShort = travel.specificDates.map((date) => 
                              DateFormat('MM/dd/yyyy').format(date).toLowerCase()
                            ).join(' ');
                          
                          return soNumber.contains(_searchQuery) || 
                                 employeeNumbers.contains(_searchQuery) ||
                                 travelDates.contains(_searchQuery) ||
                                 travelDatesShort.contains(_searchQuery);
                        });
                      }

                      if (travels.isEmpty) {
                        return Expanded(
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 50),
                              SvgPicture.asset(
                                'assets/images/dog.svg',
                                height: 100,
                              ),
                              Center(
                                child: Text(
                                  _searchQuery.isNotEmpty 
                                    ? 'No travel orders found matching "$_searchQuery"' 
                                    : 'Nothing is here yet. Add a travel order to get started.',
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

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
                                  key: ValueKey(travelModel.id),
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
                                      return Card(
                                        elevation: 3,
                                        child: ListTile(
                                          onTap: () {
                                            _showTravelFormWithEdit(
                                              travelModel,
                                            );
                                          },
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                Theme.of(context).primaryColor,
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
                                          trailing: Icon(
                                            Icons.edit_note,
                                            color:
                                                Theme.of(context).primaryColor,
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
                    return Expanded(
                      child: ListView.builder(
                        itemCount: 10,
                        itemBuilder: (context, index) {
                          return Card(
                            clipBehavior: Clip.hardEdge,
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Bone.circle(size: 48),
                              title: Bone.text(
                                words: 2,
                                style: TextStyle(fontSize: 16),
                              ),
                              subtitle: Bone.text(
                                words: 4,
                                style: TextStyle(fontSize: 10),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
