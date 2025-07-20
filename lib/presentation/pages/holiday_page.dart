import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:racconnect/data/models/holiday_model.dart';
import 'package:racconnect/logic/cubit/holiday_cubit.dart';
import 'package:racconnect/presentation/widgets/holiday_form.dart';

class HolidayPage extends StatefulWidget {
  const HolidayPage({super.key});

  @override
  State<HolidayPage> createState() => _HolidayPageState();
}

class _HolidayPageState extends State<HolidayPage> {
  final ScrollController _scrollController = ScrollController();

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
    context.read<HolidayCubit>().getAllHolidays();
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
      onRefresh: () async {
        context.read<HolidayCubit>().getAllHolidays();
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
                  trailing:
                      !isSmallScreen
                          ? ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: 150,
                              maxHeight: 40,
                            ),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add Holiday'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Theme.of(context).primaryColor,
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              onPressed: _showHolidayForm,
                            ),
                          )
                          : IconButton(
                            onPressed: _showHolidayForm,
                            icon: Icon(Icons.add, color: Colors.white),
                          ),
                ),
              ),
              SizedBox(height: 10),
              BlocBuilder<HolidayCubit, HolidayState>(
                builder: (context, state) {
                  var holidays = [];
                  if (state is HolidayLoading) {
                    return Column(
                      children: [
                        SizedBox(height: 30),
                        CircularProgressIndicator(),
                      ],
                    );
                  }

                  if (state is HolidayError) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.error),
                          backgroundColor: Colors.red,
                        ),
                      );
                    });
                  }

                  if (state is HolidayError ||
                      state is HolidayAddSuccess ||
                      state is HolidayUpdateSuccess ||
                      state is HolidayDeleteSuccess) {
                    context.read<HolidayCubit>().getAllHolidays();
                  }

                  if (state is GetAllHolidaySuccess) {
                    holidays = state.holidayModels.toList();

                    if (holidays.isNotEmpty) {
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
                                                _deleteHoliday(holidayModel.id);
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
                                      trailing: GestureDetector(
                                        onTap: () {
                                          _showHolidayFormWithEdit(
                                            holidayModel,
                                          );
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
                            'Nothing is here yet. Add a record to get started.',
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
