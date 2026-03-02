import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:racconnect/data/models/signatory_model.dart';
import 'package:racconnect/logic/cubit/signatory_cubit.dart';
import 'package:racconnect/presentation/widgets/mobile_button.dart';
import 'package:racconnect/presentation/widgets/signatory_form.dart';
import 'package:skeletonizer/skeletonizer.dart';

class SignatoryPage extends StatefulWidget {
  const SignatoryPage({super.key});

  @override
  State<SignatoryPage> createState() => _SignatoryPageState();
}

class _SignatoryPageState extends State<SignatoryPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSignatories();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _loadSignatories() async {
    setState(() {
      _isLoading = true;
    });
    await context.read<SignatoryCubit>().getSignatories();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSignatoryForm([SignatoryModel? signatory]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      scrollControlDisabledMaxHeightRatio: 0.75,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext builder) {
        return SignatoryForm(signatoryModel: signatory);
      },
    );
  }

  void _deleteSignatory(String id) {
    context.read<SignatoryCubit>().deleteSignatory(id);
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
      onRefresh: _loadSignatories,
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
                      'Signatories',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      !isSmallScreen
                          ? 'Manage signatories for each section. Pull down to refresh, or swipe left on a record to delete.'
                          : 'Manage signatories here',
                      style: const TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                    leading: const Icon(Icons.assignment_ind_rounded, color: Colors.white),
                    trailing: MobileButton(
                      isSmallScreen: isSmallScreen,
                      onPressed: () => _showSignatoryForm(),
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
                      hintText: 'Search by name or designation',
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).primaryColor,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                BlocConsumer<SignatoryCubit, SignatoryState>(
                  listener: (context, state) {
                    if (state is SignatoryError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.message),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    if (state is SignatoryLoadSuccess) {
                      final signatories = state.signatories.toList();

                      if (_searchQuery.isNotEmpty) {
                        signatories.retainWhere((s) {
                          return s.name.toLowerCase().contains(_searchQuery) ||
                              s.designation.toLowerCase().contains(_searchQuery) ||
                              (s.sectionName?.toLowerCase().contains(_searchQuery) ?? false);
                        });
                      }

                      if (signatories.isEmpty) {
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
                                      ? 'No signatories found matching "$_searchQuery"'
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
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            controller: _scrollController,
                            itemCount: signatories.length,
                            itemBuilder: (context, index) {
                              final signatory = signatories[index];
                              return ClipRect(
                                child: Dismissible(
                                  key: ValueKey(signatory.id),
                                  direction: DismissDirection.endToStart,
                                  confirmDismiss: (direction) async {
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
                                              onPressed: () => Navigator.of(context).pop(false),
                                              child: const Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(context).pop(true),
                                              child: const Text("Delete"),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  onDismissed: (_) => _deleteSignatory(signatory.id!),
                                  background: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.pink,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    alignment: Alignment.centerRight,
                                    margin: const EdgeInsets.symmetric(horizontal: 5),
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: const Icon(Icons.delete, color: Colors.white),
                                  ),
                                  child: Card(
                                    elevation: 3,
                                    child: ListTile(
                                      onTap: () => _showSignatoryForm(signatory),
                                      leading: CircleAvatar(
                                        backgroundColor: Theme.of(context).primaryColor,
                                        child: const Icon(Icons.person, color: Colors.white),
                                      ),
                                      title: Text(
                                        signatory.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${signatory.designation} (${signatory.sectionName ?? "No Section"})',
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
                            elevation: 3,
                            child: ListTile(
                              leading: const Bone.circle(size: 48),
                              title: const Bone.text(words: 2),
                              subtitle: const Bone.text(words: 4),
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
