import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:racconnect/data/models/forum_attendee.dart';
import 'package:racconnect/logic/cubit/forum_cubit.dart';
import 'package:racconnect/presentation/pages/certificate_preview_sheet.dart';
import 'package:racconnect/presentation/pages/qr_scanner_page.dart';
import 'package:racconnect/presentation/widgets/forum_attendee_form.dart';
import 'package:racconnect/presentation/widgets/mobile_button.dart';
import 'package:skeletonizer/skeletonizer.dart';

class ForumPage extends StatefulWidget {
  const ForumPage({super.key});

  @override
  State<ForumPage> createState() => _ForumPageState();
}

class _ForumPageState extends State<ForumPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  int selectedYear = DateTime.now().year;

  List<int> getYears() => List.generate(2, (i) => DateTime.now().year - i);

  void _showForumAttendeeForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      scrollControlDisabledMaxHeightRatio: 0.75,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext builder) {
        return const ForumAttendeeForm();
      },
    );
  }

  void _showForumAttendeeFormWithEdit(ForumAttendee forumAttendee) {
    showModalBottomSheet(
      context: context,
      scrollControlDisabledMaxHeightRatio: 0.75,
      showDragHandle: true,
      useSafeArea: true,
      builder: (BuildContext builder) {
        return ForumAttendeeForm(forumAttendee: forumAttendee);
      },
    );
  }

  void _showCertificatePreview(ForumAttendee attendee, {bool showSuccess = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints.expand(),
      builder: (context) =>
          CertificatePreviewSheet(attendee: attendee, showSuccess: showSuccess),
    );
  }

  void _scanQRCode() async {
    final String? scannedId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints.expand(),
      builder: (context) => const QRScannerPage(),
    );

    if (scannedId != null && mounted) {
      final state = context.read<ForumCubit>().state;
      if (state is ForumLoaded) {
        try {
          final attendee = state.allAttendees.firstWhere(
            (a) => a.id == scannedId,
          );
          _showCertificatePreview(attendee, showSuccess: true);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Attendee record not found.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }
    }
  }

  void _deleteAttendee(String id) {
    context.read<ForumCubit>().removeAttendee(id);
  }

  @override
  void initState() {
    super.initState();
    _loadAttendees();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _loadAttendees() async {
    setState(() {
      _isLoading = true;
    });
    await context.read<ForumCubit>().fetchAttendees(year: selectedYear);
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
      context.read<ForumCubit>().filterAttendeesByYear(year);
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: _scanQRCode,
        child: const Icon(Icons.qr_code_scanner),
      ),
      body: RefreshIndicator(
        triggerMode: RefreshIndicatorTriggerMode.anywhere,
        onRefresh: _loadAttendees,
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
                        'Forum Attendees',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        !isSmallScreen
                            ? 'Manage your forum attendees here. Pull down to refresh, or swipe left on a record to delete.'
                            : 'Manage your forum attendees here',
                        style:
                            const TextStyle(color: Colors.white70, fontSize: 10),
                      ),
                      leading: const Icon(
                        Icons.forum_outlined,
                        color: Colors.white,
                      ),
                      trailing: MobileButton(
                        isSmallScreen: isSmallScreen,
                        onPressed: _showForumAttendeeForm,
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
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search by name or address',
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
                                  vertical: 10, horizontal: 12),
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
                  BlocConsumer<ForumCubit, ForumState>(
                    listener: (context, state) {
                      if (state is ForumError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(state.message),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else if (state is ForumAddSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Attendee added successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _loadAttendees();
                      } else if (state is ForumUpdateSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Attendee updated successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _loadAttendees();
                      } else if (state is ForumDeleteSuccess) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Attendee deleted successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        _loadAttendees();
                      }
                    },
                    builder: (context, state) {
                      if (state is ForumLoaded) {
                        final attendees = state.attendees.toList();

                        // Apply search filter
                        if (_searchQuery.isNotEmpty) {
                          attendees.retainWhere((attendee) {
                            final attendeeName = attendee.name.toLowerCase();
                            final attendeeAddress =
                                attendee.address.toLowerCase();
                            return attendeeName.contains(_searchQuery) ||
                                attendeeAddress.contains(_searchQuery);
                          });
                        }

                        if (attendees.isEmpty) {
                          return Expanded(
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                const SizedBox(height: 50),
                                SvgPicture.asset(
                                  'assets/images/group_fun.svg',
                                  height: 100,
                                ),
                                Center(
                                  child: Text(
                                    _searchQuery.isNotEmpty
                                        ? 'No attendees found matching "$_searchQuery"'
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
                              controller: _scrollController,
                              itemCount: attendees.length,
                              itemBuilder: (context, index) {
                                final attendee = attendees[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 5,
                                    horizontal: 3,
                                  ),
                                  child: Dismissible(
                                    key: Key(attendee.id),
                                    direction: DismissDirection.endToStart,
                                    onDismissed: (direction) {
                                      _deleteAttendee(attendee.id);
                                    },
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
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
                                          _showCertificatePreview(attendee);
                                        },
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              Theme.of(context).primaryColor,
                                          child: Text(
                                            attendee.name.isNotEmpty
                                                ? attendee.name[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                        ),
                                        title: Text(
                                          attendee.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                        ),
                                        subtitle: Text(
                                          attendee.address,
                                          style: const TextStyle(fontSize: 10),
                                        ),
                                        trailing: IconButton(
                                          icon: Icon(
                                            Icons.edit_note,
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                          onPressed: () {
                                            _showForumAttendeeFormWithEdit(
                                                attendee);
                                          },
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
                                title: const Bone.text(
                                  words: 2,
                                  style: TextStyle(fontSize: 16),
                                ),
                                subtitle: const Bone.text(
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
      ),
    );
  }
}
