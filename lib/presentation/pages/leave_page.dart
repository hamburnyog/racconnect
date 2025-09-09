import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/leave_model.dart';
import 'package:racconnect/data/models/user_model.dart';
import 'package:racconnect/data/repositories/auth_repository.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';
import 'package:racconnect/logic/cubit/leave_cubit.dart';
import 'package:racconnect/presentation/widgets/leave_form.dart';
import 'package:racconnect/presentation/widgets/mobile_button.dart';
import 'package:skeletonizer/skeletonizer.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  OverlayEntry? _overlayEntry;
  final ScrollController _scrollController = ScrollController();
  List<UserModel> _allUsers = [];
  bool _isLoading = true;

  void _showLeaveForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      scrollControlDisabledMaxHeightRatio: 0.9,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext builder) {
        return const LeaveForm();
      },
    );
  }

  void _showLeaveFormWithEdit(LeaveModel leaveModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      scrollControlDisabledMaxHeightRatio: 0.9,
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

  String _formatLeaveDates(List<DateTime> dates) {
    if (dates.isEmpty) return 'No dates';

    // Sort dates
    dates.sort((a, b) => a.compareTo(b));

    if (dates.length == 1) {
      return DateFormat('MMM d, yyyy').format(dates.first);
    } else {
      return '${DateFormat('MMM d, yyyy').format(dates.first)} - ${DateFormat('MMM d, yyyy').format(dates.last)}';
    }
  }

  String _createTooltipMessage(LeaveModel leaveModel) {
    final employeeNames = _getEmployeeNames(leaveModel.employeeNumbers);
    final buffer = StringBuffer();

    buffer.writeln('Staff:');
    for (final name in employeeNames) {
      buffer.writeln('  • $name');
    }

    if (leaveModel.specificDates.isNotEmpty) {
      buffer.writeln('Dates:');
      final sortedDates = List<DateTime>.from(leaveModel.specificDates)
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
    LeaveModel leaveModel,
  ) {
    _removeTooltip();
    final overlay = Overlay.of(context);
    final tooltip = _createTooltipMessage(leaveModel);

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
      builder: (context) => Stack(
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
    _loadLeaves();
  }

  Future<void> _loadLeaves() async {
    setState(() {
      _isLoading = true;
    });
    await context.read<LeaveCubit>().getAllLeaves();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
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
                              'Leaves',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            subtitle: Text(
                              !isSmallScreen
                                  ? 'Manage leaves here. Pull down to refresh, or swipe left on a record to delete.'
                                  : 'Manage leaves here',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                            leading: const Icon(
                              Icons.sick_outlined,
                              color: Colors.white,
                            ),
                            trailing: MobileButton(
                              isSmallScreen: isSmallScreen,
                              onPressed: _showLeaveForm,
                              icon: const Icon(Icons.add),
                              label: 'Add',
                            ),
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
                              final leaves = state.leaveModels.toList();

                              if (leaves.isEmpty) {
                                return Expanded(
                                  child: ListView(
                                    physics: const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      const SizedBox(height: 50),
                                      SvgPicture.asset(
                                        'assets/images/dog.svg',
                                        height: 100,
                                      ),
                                      const Center(
                                        child: Text(
                                          'Nothing is here yet. Add a leave to get started.',
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
                                                    "Are you sure you want to delete this leave?",
                                                  ),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(context).pop(false),
                                                      child: const Text("Cancel"),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        _deleteLeave(
                                                          leaveModel.id!,
                                                        );
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
                                                      context.findRenderObject() as RenderBox;
                                                  final size = renderBox.size;
                                                  final position =
                                                      renderBox.localToGlobal(Offset.zero);
                                                  _showTooltip(
                                                    context,
                                                    position,
                                                    size,
                                                    leaveModel,
                                                  );
                                                },
                                                child: Card(
                                                  elevation: 3,
                                                  child: ListTile(
                                                    leading: CircleAvatar(
                                                      backgroundColor:
                                                          Theme.of(context).primaryColor,
                                                      child: const Icon(
                                                        Icons.sick_outlined,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    title: Text(
                                                      leaveModel.type,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: Theme.of(context).primaryColor,
                                                      ),
                                                    ),
                                                    subtitle: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          '${leaveModel.employeeNumbers.length} employee${leaveModel.employeeNumbers.length != 1 ? 's' : ''}, ${leaveModel.specificDates.length} date${leaveModel.specificDates.length != 1 ? 's' : ''}',
                                                          style: const TextStyle(
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                        if (leaveModel.specificDates.isNotEmpty)
                                                          Text(
                                                            _formatLeaveDates(
                                                              leaveModel.specificDates,
                                                            ),
                                                            style: const TextStyle(
                                                              fontSize: 10,
                                                            ),
                                                          ),
                                                      ],
                                                    ),
                                                    trailing: GestureDetector(
                                                      onTap: () {
                                                        _showLeaveFormWithEdit(
                                                          leaveModel,
                                                        );
                                                      },
                                                      child: Icon(
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
                                        style: TextStyle(
                                          fontSize: 16,
                                        ),
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
        return Center(child: Text('You do not have access to this page.'));
      },
    );
  }
}
