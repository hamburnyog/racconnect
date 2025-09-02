import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/leave_model.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';
import 'package:racconnect/logic/cubit/leave_cubit.dart';
import 'package:racconnect/presentation/widgets/leave_form.dart';
import 'package:racconnect/presentation/widgets/mobile_button.dart';

class LeavePage extends StatefulWidget {
  const LeavePage({super.key});

  @override
  State<LeavePage> createState() => _LeavePageState();
}

class _LeavePageState extends State<LeavePage> {
  final ScrollController _scrollController = ScrollController();

  void _showLeaveForm(String employeeNumber) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      scrollControlDisabledMaxHeightRatio: 0.75,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext builder) {
        return LeaveForm(employeeNumber: employeeNumber);
      },
    );
  }

  void _showLeaveFormWithEdit(LeaveModel leaveModel, String employeeNumber) {
    showModalBottomSheet(
      context: context,
      scrollControlDisabledMaxHeightRatio: 0.75,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext builder) {
        return LeaveForm(leaveModel: leaveModel, employeeNumber: employeeNumber);
      },
    );
  }

  void _deleteLeave(String id) {
    context.read<LeaveCubit>().deleteLeave(id: id);
  }

  @override
  void initState() {
    super.initState();
    // We'll load leaves in the build method after getting the employee number
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isSmallScreen = width < 700;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is AuthenticatedState) {
          final employeeNumber = authState.user.profile?.employeeNumber ?? '';
          
          // Load leaves for the current user
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (employeeNumber.isNotEmpty) {
              context.read<LeaveCubit>().getAllLeaves(employeeNumber: employeeNumber);
            }
          });

          return RefreshIndicator(
            triggerMode: RefreshIndicatorTriggerMode.anywhere,
            onRefresh: () async {
              if (employeeNumber.isNotEmpty) {
                context.read<LeaveCubit>().getAllLeaves(employeeNumber: employeeNumber);
              }
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
                        title: Text(
                          'Leaves',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        subtitle: Text(
                          !isSmallScreen
                              ? 'View your leave dates here. Pull down to refresh, or swipe left on a record to delete.'
                              : 'View your leave dates here',
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                        leading: Icon(
                          Icons.sick_outlined,
                          color: Colors.white,
                        ),
                        trailing: MobileButton(
                          isSmallScreen: isSmallScreen,
                          onPressed: () => _showLeaveForm(employeeNumber),
                          icon: const Icon(Icons.add),
                          label: 'Add',
                        ),
                      ),
                    ),
                    BlocBuilder<LeaveCubit, LeaveState>(
                      builder: (context, state) {
                        var leaves = [];
                        if (state is LeaveLoading) {
                          return Column(
                            children: [
                              SizedBox(height: 30),
                              CircularProgressIndicator(),
                            ],
                          );
                        }

                        if (state is LeaveError) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(state.error),
                                backgroundColor: Colors.red,
                              ),
                            );
                          });
                        }

                        if (state is LeaveError ||
                            state is LeaveAddSuccess ||
                            state is LeaveUpdateSuccess ||
                            state is LeaveDeleteSuccess) {
                          if (employeeNumber.isNotEmpty) {
                            context.read<LeaveCubit>().getAllLeaves(employeeNumber: employeeNumber);
                          }
                        }

                        if (state is GetAllLeaveSuccess) {
                          leaves = state.leaveModels.toList();

                          if (leaves.isNotEmpty) {
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
                                        key: UniqueKey(),
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
                                                  "Are you sure you want to delete this leave date?",
                                                ),
                                                actions: <Widget>[
                                                  TextButton(
                                                    onPressed: () => Navigator.of(
                                                      context,
                                                    ).pop(false),
                                                    child: const Text("Cancel"),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      _deleteLeave(leaveModel.id!);
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
                                            leading: CircleAvatar(
                                              backgroundColor:
                                                  Theme.of(context).primaryColor,
                                              child: Icon(
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
                                            subtitle: Text(
                                              DateFormat('MMM d, yyyy').format(leaveModel.date),
                                              style: TextStyle(fontSize: 10),
                                            ),
                                            trailing: GestureDetector(
                                              onTap: () {
                                                _showLeaveFormWithEdit(leaveModel, employeeNumber);
                                              },
                                              child: Icon(
                                                Icons.edit_note,
                                                color: Theme.of(context).primaryColor,
                                              ),
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
                        }
                        return Expanded(
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: 50),
                              SvgPicture.asset('assets/images/dog.svg', height: 100),
                              Center(
                                child: Text(
                                  'No leave dates recorded yet. Add leave dates to get started.',
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
        return Center(child: Text('Authentication required'));
      },
    );
  }
}