import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:racconnect/logic/cubit/section_cubit.dart';
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
      scrollControlDisabledMaxHeightRatio: 0.75,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext builder) {
        return SectionForm();
      },
    );
  }

  void addSection() {}

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
                  subtitle:
                      MediaQuery.of(context).size.width > 600
                          ? Text(
                            'Manage your sections here. Pull down to refresh, or swipe left on a record to delete.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          )
                          : null,
                  leading: Icon(Icons.group_rounded, color: Colors.white),
                  trailing:
                      MediaQuery.of(context).size.width > 600
                          ? ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: 150),
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add Section'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Theme.of(context).primaryColor,
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              onPressed: _showSectionForm,
                            ),
                          )
                          : IconButton(
                            onPressed: _showSectionForm,
                            icon: Icon(Icons.add, color: Colors.white),
                          ),
                ),
              ),
              SizedBox(height: 10),
              BlocBuilder<SectionCubit, SectionState>(
                builder: (context, state) {
                  if (state is SectionLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is SectionError) {
                    return Center(
                      child: Text(
                        state.error,
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  if (state is GetAllSectionSuccess) {
                    final sections = state.sectionModels.toList();

                    if (sections.isEmpty) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 50),
                          SvgPicture.asset(
                            'assets/images/dog.svg',
                            height: 100,
                          ),
                          Text(
                            'Nothing is here yet. Add a record to get started.',
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
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
                                    trailing: IconButton(
                                      icon: Icon(
                                        Icons.edit,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                      onPressed: _showSectionForm,
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
                  return const Center(child: Text('Something went wrong.'));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
