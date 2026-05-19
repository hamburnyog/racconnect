import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/leave_model.dart';
import 'package:racconnect/data/blocs/cubit/auth_cubit.dart';
import 'package:racconnect/data/blocs/cubit/leave_cubit.dart';
import 'package:racconnect/presentation/widgets/leave_form.dart';
import 'package:skeletonizer/skeletonizer.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  int selectedYear = DateTime.now().year;

  List<int> getYears() => List.generate(2, (i) => DateTime.now().year - i);

  void _showLeaveFormWithEdit(LeaveModel leaveModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      scrollControlDisabledMaxHeightRatio: 0.75,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext builder) {
        return LeaveForm(leaveModel: leaveModel);
      },
    );
  }

  void _deleteLeave(String id) {
    context.read<LeaveCubit>().deleteLeave(id: id);
  }

  @override
  void initState() {
    super.initState();
    _loadLeaves();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _loadLeaves() async {
    setState(() {
      _isLoading = true;
    });
    await context.read<LeaveCubit>().getAllLeaves(year: selectedYear);
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
      context.read<LeaveCubit>().filterLeavesByYear(year);
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
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is AuthenticatedState) {
          final userRole = authState.user.role;
          if (userRole == 'Developer' || userRole == 'HR') {
            return RefreshIndicator(
              triggerMode: RefreshIndicatorTriggerMode.anywhere,
              onRefresh: _loadLeaves,
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                    PointerDeviceKind.trackpad,
                  },
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
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
                                        EdgeInsets.symmetric(vertical: 10),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
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
                                    contentPadding: EdgeInsets.symmetric(
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
                        BlocConsumer<LeaveCubit, LeaveState>(
                          listener: (context, state) {
                            if (state is LeaveError) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(state.error),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            } else if (state is LeaveAddSuccess) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Leave added successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadLeaves();
                            } else if (state is LeaveUpdateSuccess) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Leave updated successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadLeaves();
                            } else if (state is LeaveDeleteSuccess) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Leave deleted successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              _loadLeaves();
                            }
                          },
                          builder: (context, state) {
                            if (state is GetAllLeaveSuccess) {
                              final leaves = state.filteredLeaveModels.toList();

                              // Apply search filter
                              if (_searchQuery.isNotEmpty) {
                                leaves.retainWhere((leave) {
                                  final leaveType = leave.type.toLowerCase();
                                  final hasMatchingDate =
                                      leave.specificDates.any((date) {
                                        final leaveDate =
                                            DateFormat(
                                              'MMMM d, yyyy',
                                            ).format(date).toLowerCase();
                                        final leaveDateShort =
                                            DateFormat(
                                              'MM/dd/yyyy',
                                            ).format(date).toLowerCase();
                                        final leaveDateYear =
                                            date.year.toString();
                                        final leaveDateMonth =
                                            DateFormat(
                                              'MMMM',
                                            ).format(date).toLowerCase();
                                        final leaveDateDay =
                                            date.day.toString();

                                        return leaveDate.contains(
                                              _searchQuery,
                                            ) ||
                                            leaveDateShort.contains(
                                              _searchQuery,
                                            ) ||
                                            leaveDateYear.contains(
                                              _searchQuery,
                                            ) ||
                                            leaveDateMonth.contains(
                                              _searchQuery,
                                            ) ||
                                            leaveDateDay.contains(_searchQuery);
                                      });

                                  return leaveType.contains(_searchQuery) ||
                                      hasMatchingDate;
                                });
                              }

                              if (leaves.isEmpty) {
                                return Expanded(
                                  child: ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      SizedBox(height: 50),
                                      SvgPicture.asset(
                                        'assets/images/dog.svg',
                                        height: 100,
                                      ),
                                      Center(
                                        child: Text(
                                          _searchQuery.isNotEmpty
                                              ? 'No leaves found matching "$_searchQuery"'
                                              : 'Nothing is here yet. Add a record to get started.',
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
                                    physics: AlwaysScrollableScrollPhysics(),
                                    scrollDirection: Axis.vertical,
                                    controller: _scrollController,
                                    itemCount: leaves.length,
                                    itemBuilder: (context, index) {
                                      final leaveModel = leaves[index];
                                      return ClipRect(
                                        child: Dismissible(
                                          key: ValueKey(leaveModel.id),
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
                                                      child: const Text(
                                                        "Cancel",
                                                      ),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        if (leaveModel.id !=
                                                            null) {
                                                          _deleteLeave(
                                                            leaveModel.id!,
                                                          );
                                                        }
                                                        Navigator.of(
                                                          context,
                                                        ).pop(true);
                                                      },
                                                      child: const Text(
                                                        "Delete",
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          background: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.pink,
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                                _showLeaveFormWithEdit(
                                                  leaveModel,
                                                );
                                              },
                                              leading: CircleAvatar(
                                                backgroundColor:
                                                    Theme.of(context)
                                                        .primaryColor,
                                                child: Icon(
                                                  Icons.sick_outlined,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              title: Text(
                                                leaveModel.type,
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color:
                                                      Theme.of(context)
                                                          .primaryColor,
                                                ),
                                              ),
                                              subtitle: Text(
                                                leaveModel
                                                        .specificDates
                                                        .isNotEmpty
                                                    ? DateFormat(
                                                      'MMMM d, yyyy',
                                                    ).format(
                                                      leaveModel
                                                          .specificDates
                                                          .first,
                                                    )
                                                    : 'No date specified',
                                                style: TextStyle(fontSize: 10),
                                              ),
                                              trailing: Icon(
                                                Icons.edit_note,
                                                color:
                                                    Theme.of(context)
                                                        .primaryColor,
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
        return const Center(
          child: Text('Access Denied or Not Authenticated'),
        );
      },
    );
  }
}
