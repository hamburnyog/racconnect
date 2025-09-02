import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:racconnect/data/models/section_model.dart';
import 'package:racconnect/logic/cubit/section_cubit.dart';
import 'package:racconnect/presentation/widgets/mobile_button.dart';
import 'package:racconnect/presentation/widgets/section_form.dart';

class SectionPage extends StatefulWidget {
  const SectionPage({super.key});

  @override
  State<SectionPage> createState() => _SectionPageState();
}

class _SectionPageState extends State<SectionPage> {
  final ScrollController _scrollController = ScrollController();

  void _showSectionForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      scrollControlDisabledMaxHeightRatio: 0.75,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext builder) {
        return SectionForm();
      },
    );
  }

  void _showSectionFormWithEdit(SectionModel sectionModel) {
    showModalBottomSheet(
      context: context,
      scrollControlDisabledMaxHeightRatio: 0.75,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext builder) {
        return SectionForm(sectionModel: sectionModel);
      },
    );
  }

  void _deleteSection(String id) {
    context.read<SectionCubit>().deleteSection(id: id);
  }

  @override
  void initState() {
    super.initState();
    context.read<SectionCubit>().getAllSections();
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
        context.read<SectionCubit>().getAllSections();
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
                    'Sections',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    !isSmallScreen
                        ? 'Manage your sections here. Pull down to refresh, or swipe left on a record to delete.'
                        : 'Manage your sections here',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                  leading: Icon(Icons.group_rounded, color: Colors.white),
                  trailing: MobileButton(
                    isSmallScreen: isSmallScreen,
                    onPressed: _showSectionForm,
                    icon: Icons.add,
                    label: 'Add',
                  ),
                ),
              ),
              BlocBuilder<SectionCubit, SectionState>(
                builder: (context, state) {
                  var sections = [];
                  if (state is SectionLoading) {
                    return Column(
                      children: [
                        SizedBox(height: 30),
                        CircularProgressIndicator(),
                      ],
                    );
                  }

                  if (state is SectionError) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.error),
                          backgroundColor: Colors.red,
                        ),
                      );
                    });
                  }

                  if (state is SectionError ||
                      state is SectionAddSuccess ||
                      state is SectionUpdateSuccess ||
                      state is SectionDeleteSuccess) {
                    context.read<SectionCubit>().getAllSections();
                  }

                  if (state is GetAllSectionSuccess) {
                    sections = state.sectionModels.toList();

                    if (sections.isNotEmpty) {
                      return Expanded(
                        child: Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          interactive: true,
                          child: ListView.builder(
                            physics: AlwaysScrollableScrollPhysics(),
                            scrollDirection: Axis.vertical,
                            controller: _scrollController,
                            itemCount: sections.length,
                            itemBuilder: (context, index) {
                              final sectionModel = sections[index];
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
                                                _deleteSection(sectionModel.id);
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
                                          Icons.group,
                                          color: Colors.white,
                                        ),
                                      ),
                                      title: Text(
                                        sectionModel.code,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                      subtitle: Text(
                                        sectionModel.name,
                                        style: TextStyle(fontSize: 10),
                                      ),
                                      trailing: GestureDetector(
                                        onTap: () {
                                          _showSectionFormWithEdit(
                                            sectionModel,
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
