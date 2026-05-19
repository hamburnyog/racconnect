import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/travel_model.dart';
import 'package:racconnect/data/blocs/cubit/travel_cubit.dart';
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
  int selectedYear = DateTime.now().year;

  List<int> getYears() => List.generate(2, (i) => DateTime.now().year - i);

  void _showTravelFormWithEdit(TravelModel travelModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      scrollControlDisabledMaxHeightRatio: 0.75,
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
    await context.read<TravelCubit>().getAllTravels(year: selectedYear);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onYearChanged(int? year) {
    if (year != null) {
      setState(() {
        selectedYear = year;
      });
      context.read<TravelCubit>().filterTravelsByYear(year);
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
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8.0,
                    horizontal: 3.0,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search',
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
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: selectedYear,
                          decoration: InputDecoration(
                            labelText: 'Year',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 12,
                            ),
                          ),
                          items: getYears().map((y) {
                            return DropdownMenuItem(
                              value: y,
                              child: Text('$y'),
                            );
                          }).toList(),
                          onChanged: _onYearChanged,
                        ),
                      ),
                    ],
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
                      final travels = state.filteredTravelModels.toList();

                      // Apply search filter
                      if (_searchQuery.isNotEmpty) {
                        travels.retainWhere((travel) {
                          final soNumber = travel.soNumber.toLowerCase();
                          bool dateMatch = false;
                          for (var date in travel.specificDates) {
                            final dateStr =
                                DateFormat('MMMM d, yyyy').format(date).toLowerCase();
                            final dateShort =
                                DateFormat('MM/dd/yyyy').format(date).toLowerCase();
                            if (dateStr.contains(_searchQuery) ||
                                dateShort.contains(_searchQuery)) {
                              dateMatch = true;
                              break;
                            }
                          }

                          return soNumber.contains(_searchQuery) || dateMatch;
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
                                      ? 'No travels found matching "$_searchQuery"'
                                      : 'Nothing is here yet. Add a record to get started.',
                                  style: const TextStyle(fontSize: 10),
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
                              final displayDate = travelModel.specificDates.isNotEmpty
                                  ? DateFormat('MMMM d, yyyy')
                                      .format(travelModel.specificDates.first)
                                  : 'No dates';

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
                                            "Are you sure you want to delete this record?",
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
                                                if (travelModel.id != null) {
                                                  _deleteTravel(
                                                    travelModel.id!,
                                                  );
                                                }
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
                                  child: Card(
                                    elevation: 3,
                                    child: ListTile(
                                      onTap: () {
                                        _showTravelFormWithEdit(travelModel);
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
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                      subtitle: Text(
                                        displayDate,
                                        style: const TextStyle(fontSize: 10),
                                      ),
                                      trailing: Icon(
                                        Icons.edit_note,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
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
                              leading: const Bone.circle(size: 48),
                              title: Bone.text(
                                words: 2,
                                style: const TextStyle(fontSize: 16),
                              ),
                              subtitle: Bone.text(
                                words: 4,
                                style: const TextStyle(fontSize: 10),
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
