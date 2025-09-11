import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/holiday_model.dart';
import 'package:racconnect/logic/cubit/holiday_cubit.dart';
import 'package:racconnect/presentation/widgets/holiday_form.dart';
import 'package:racconnect/presentation/widgets/mobile_button.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HolidayPage extends StatefulWidget {
  const HolidayPage({super.key});

  @override
  State<HolidayPage> createState() => _HolidayPageState();
}

class _HolidayPageState extends State<HolidayPage> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;

  void _showHolidayForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      scrollControlDisabledMaxHeightRatio: 0.75,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext builder) {
        return HolidayForm();
      },
    );
  }

  void _showHolidayFormWithEdit(HolidayModel holidayModel) {
    showModalBottomSheet(
      context: context,
      scrollControlDisabledMaxHeightRatio: 0.75,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext builder) {
        return HolidayForm(holidayModel: holidayModel);
      },
    );
  }

  void _deleteHoliday(String id) {
    context.read<HolidayCubit>().deleteHoliday(id: id);
  }

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    setState(() {
      _isLoading = true;
    });
    await context.read<HolidayCubit>().getAllHolidays();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
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

    return RefreshIndicator(
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      onRefresh: _loadHolidays,
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
                    title: Text(
                      'Holidays',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      !isSmallScreen
                          ? 'Manage your holidays here. Pull down to refresh, or swipe left on a record to delete.'
                          : 'Manage your holidays here',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    leading: Icon(
                      Icons.calendar_month_outlined,
                      color: Colors.white,
                    ),
                    trailing: MobileButton(
                      isSmallScreen: isSmallScreen,
                      onPressed: _showHolidayForm,
                      icon: const Icon(Icons.add),
                      label: 'Add',
                    ),
                  ),
                ),
                BlocConsumer<HolidayCubit, HolidayState>(
                  listener: (context, state) {
                    if (state is HolidayError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.error),
                          backgroundColor: Colors.red,
                        ),
                      );
                    } else if (state is HolidayAddSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Holiday added successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadHolidays();
                    } else if (state is HolidayUpdateSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Holiday updated successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadHolidays();
                    } else if (state is HolidayDeleteSuccess) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Holiday deleted successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadHolidays();
                    }
                  },
                  builder: (context, state) {
                    if (state is GetAllHolidaySuccess) {
                      final holidays = state.holidayModels.toList();

                      if (holidays.isEmpty) {
                        return Expanded(
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: 50),
                              SvgPicture.asset(
                                'assets/images/dog.svg',
                                height: 100,
                              ),
                              Center(
                                child: Text(
                                  'Nothing is here yet. Add a record to get started.',
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
                            itemCount: holidays.length,
                            itemBuilder: (context, index) {
                              final holidayModel = holidays[index];
                              return ClipRect(
                                child: Dismissible(
                                  key: ValueKey(holidayModel.id),
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
                                              onPressed: () =>
                                                  Navigator.of(context).pop(false),
                                              child: const Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                if (holidayModel.id != null) {
                                                  _deleteHoliday(
                                                    holidayModel.id!,
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
                                        _showHolidayFormWithEdit(
                                          holidayModel,
                                        );
                                      },
                                      leading: CircleAvatar(
                                        backgroundColor:
                                            Theme.of(context).primaryColor,
                                        child: Icon(
                                          Icons.calendar_month_outlined,
                                          color: Colors.white,
                                        ),
                                      ),
                                      title: Text(
                                        holidayModel.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                      subtitle: Text(
                                        DateFormat(
                                          'MMMM d, yyyy',
                                        ).format(holidayModel.date),
                                        style: TextStyle(fontSize: 10),
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
