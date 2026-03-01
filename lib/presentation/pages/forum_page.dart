import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import 'package:racconnect/data/models/forum_attendee.dart';
import 'package:racconnect/data/repositories/forum_repository.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';
import 'package:racconnect/logic/cubit/forum_cubit.dart';
import 'package:racconnect/presentation/pages/certificate_preview_sheet.dart';
import 'package:racconnect/presentation/pages/qr_scanner_page.dart';
import 'package:racconnect/presentation/widgets/forum_attendee_form.dart';
import 'package:racconnect/presentation/widgets/mobile_button.dart';
import 'package:racconnect/utility/forum_email_sender.dart';
import 'package:racconnect/utility/forum_import.dart';
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
  String _statusFilter = 'All';

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

  void _showCertificatePreview(
    ForumAttendee attendee, {
    bool showSuccess = false,
    bool isAuthorized = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      constraints: const BoxConstraints.expand(),
      builder: (context) => CertificatePreviewSheet(
        attendee: attendee,
        showSuccess: showSuccess,
        isAuthorized: isAuthorized,
      ),
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
      final authState = context.read<AuthCubit>().state;
      String role = '';
      if (authState is AuthenticatedState) {
        role = authState.user.role ?? '';
      }
      final bool isAuthorized = role == 'Developer' || role == 'IO';

      if (state is ForumLoaded) {
        try {
          final attendee = state.allAttendees.firstWhere(
            (a) => a.id == scannedId,
          );
          _showCertificatePreview(
            attendee,
            showSuccess: true,
            isAuthorized: isAuthorized,
          );
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

  void _importCSV() async {
    final importer = ForumImport(
      context: context,
      onImportSuccess: _loadAttendees,
    );
    await importer.pickAndImportFile();
  }

  Future<void> _sendAllUnsent() async {
    final state = context.read<ForumCubit>().state;
    if (state is ForumLoaded) {
      final unsent = state.allAttendees
          .where((a) => a.emailSentDate == null && a.email.isNotEmpty)
          .toList();

      if (unsent.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No unsent certificates with email addresses found.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final sender = ForumEmailSender(
        context: context,
        attendees: unsent,
      );
      await sender.sendEmails();
    }
  }

  Future<void> _markAllAsSent() async {
    final state = context.read<ForumCubit>().state;
    if (state is! ForumLoaded) return;

    final unsent =
        state.allAttendees.where((a) => a.emailSentDate == null).toList();

    if (unsent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No unsent certificates to mark.')),
      );
      return;
    }

    final ValueNotifier<double> progress = ValueNotifier(0.0);
    final repository = ForumRepository();

    if (!mounted) return;

    // Show Progress Dialog
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      pageBuilder: (dialogCtx, _, __) {
        return AlertDialog(
          title: const Text('Marking as Sent'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Updating records...'),
              const SizedBox(height: 16),
              ValueListenableBuilder<double>(
                valueListenable: progress,
                builder: (_, val, __) => LinearProgressIndicator(value: val),
              ),
            ],
          ),
        );
      },
    );

    int count = 0;
    final now = DateTime.now();

    for (var attendee in unsent) {
      try {
        await repository.updateAttendee(
          attendee.id,
          ForumAttendee(
            id: attendee.id,
            name: attendee.name,
            address: attendee.address,
            email: attendee.email,
            type: attendee.type,
            forumDate: attendee.forumDate,
            emailSentDate: now,
          ),
        );
        count++;
      } catch (_) {}
      progress.value = count / unsent.length;
    }

    if (mounted) {
      Navigator.of(context).pop(); // Close dialog
      _loadAttendees(); // Refresh list
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully marked $count certificates as sent.'),
          backgroundColor: Colors.green,
        ),
      );
    }
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
    await context.read<ForumCubit>().fetchAttendees();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
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

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        String role = '';
        if (authState is AuthenticatedState) {
          role = authState.user.role ?? '';
        }
        final bool isAuthorized = role == 'Developer' || role == 'IO';

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              RefreshIndicator(
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    child: Skeletonizer(
                      enabled: _isLoading,
                      child: Column(
                        children: [
                          Card(
                            color: Theme.of(context).primaryColor,
                            child: ListTile(
                              minTileHeight: 70,
                              title: const Text(
                                'Certificates',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                !isSmallScreen
                                    ? 'Manage forum certificates here. Pull down to refresh, or swipe left on a record to delete.'
                                    : 'Manage certificates here',
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 10),
                              ),
                              leading: const Icon(
                                Icons.card_membership_rounded,
                                color: Colors.white,
                              ),
                              trailing: isAuthorized
                                  ? MobileButton(
                                      isSmallScreen: isSmallScreen,
                                      onPressed: _showForumAttendeeForm,
                                      icon: const Icon(Icons.add),
                                      label: 'Add',
                                    )
                                  : null,
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
                                      hintText: 'Search by name, address or date',
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
                                      contentPadding: const EdgeInsets.symmetric(
                                          vertical: 10),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    initialValue: _statusFilter,
                                    decoration: InputDecoration(
                                      labelText: 'Status',
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
                                    items: ['All', 'Sent', 'Unsent'].map((status) {
                                      return DropdownMenuItem(
                                        value: status,
                                        child: Text(status),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _statusFilter = value;
                                        });
                                      }
                                    },
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
                                    content:
                                        Text('Certificate added successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _loadAttendees();
                              } else if (state is ForumUpdateSuccess) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Certificate updated successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _loadAttendees();
                              } else if (state is ForumUpdateSilentSuccess) {
                                _loadAttendees();
                              } else if (state is ForumDeleteSuccess) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Certificate deleted successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _loadAttendees();
                              }
                            },
                            builder: (context, state) {
                              if (state is ForumLoaded) {
                                final attendees = state.allAttendees.toList();

                                // Apply search filter
                                if (_searchQuery.isNotEmpty) {
                                  attendees.retainWhere((attendee) {
                                    final attendeeName =
                                        attendee.name.toLowerCase();
                                    final attendeeAddress =
                                        attendee.address.toLowerCase();
                                    final forumDateStr = attendee.forumDate !=
                                            null
                                        ? DateFormat('MMMM d, yyyy')
                                            .format(attendee.forumDate!)
                                            .toLowerCase()
                                        : '';
                                    return attendeeName.contains(_searchQuery) ||
                                        attendeeAddress.contains(_searchQuery) ||
                                        forumDateStr.contains(_searchQuery);
                                  });
                                }

                                // Apply status filter
                                if (_statusFilter == 'Sent') {
                                  attendees.retainWhere((attendee) =>
                                      attendee.emailSentDate != null);
                                } else if (_statusFilter == 'Unsent') {
                                  attendees.retainWhere((attendee) =>
                                      attendee.emailSentDate == null);
                                }

                                // Apply sorting: Sent first, then by latest date
                                attendees.sort((a, b) {
                                  // 1. Sent vs Unsent
                                  if (a.emailSentDate != null &&
                                      b.emailSentDate == null) {
                                    return -1; // a comes first
                                  }
                                  if (a.emailSentDate == null &&
                                      b.emailSentDate != null) {
                                    return 1; // b comes first
                                  }

                                  // 2. If both sent, latest emailSentDate first
                                  if (a.emailSentDate != null &&
                                      b.emailSentDate != null) {
                                    return b.emailSentDate!
                                        .compareTo(a.emailSentDate!);
                                  }

                                  // 3. If both unsent, latest forumDate first
                                  final dateA = a.forumDate ?? DateTime(0);
                                  final dateB = b.forumDate ?? DateTime(0);
                                  return dateB.compareTo(dateA);
                                });

                                if (attendees.isEmpty) {
                                  return Expanded(
                                    child: ListView(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
                                      children: [
                                        const SizedBox(height: 50),
                                        SvgPicture.asset(
                                          'assets/images/group_fun.svg',
                                          height: 100,
                                        ),
                                        Center(
                                          child: Text(
                                            _searchQuery.isNotEmpty
                                                ? 'No certificates found matching "$_searchQuery"'
                                                : 'Nothing is here yet. Add a record to get started.',
                                            style: const TextStyle(fontSize: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return Expanded(
                                  child: ClipRect(
                                    child: Scrollbar(
                                      controller: _scrollController,
                                      thumbVisibility: true,
                                      interactive: true,
                                      child: ListView.builder(
                                      physics:
                                          const AlwaysScrollableScrollPhysics(),
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
                                            direction: isAuthorized
                                                ? DismissDirection.endToStart
                                                : DismissDirection.none,
                                            confirmDismiss: (direction) async {
                                              return await showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                  title: const Text(
                                                      'Confirm Delete'),
                                                  content: Text(
                                                      'Are you sure you want to delete the certificate for ${attendee.name}?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, false),
                                                      child: const Text(
                                                          'Cancel'),
                                                    ),
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, true),
                                                      child: const Text(
                                                        'Delete',
                                                        style: TextStyle(
                                                            color: Colors.red),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                            onDismissed: (direction) {
                                              _deleteAttendee(attendee.id);
                                            },
                                            background: Container(
                                              alignment: Alignment.centerRight,
                                              decoration: BoxDecoration(
                                                color: Colors.red,
                                                borderRadius:
                                                    BorderRadius.circular(12),
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
                                                                                          _showCertificatePreview(
                                                                                            attendee,
                                                                                            isAuthorized: isAuthorized,
                                                                                          );
                                                                                        },
                                                                                        leading: Tooltip(                                                  message:
                                                      attendee.emailSentDate !=
                                                              null
                                                          ? 'Sent on ${DateFormat('MMM dd, yyyy').format(attendee.emailSentDate!)}'
                                                          : 'Not sent yet',
                                                  child: CircleAvatar(
                                                    backgroundColor: attendee
                                                                .emailSentDate !=
                                                            null
                                                        ? Colors.green
                                                        : Colors.grey.shade300,
                                                    child: attendee.emailSentDate !=
                                                            null
                                                        ? const Icon(
                                                            Icons
                                                                .mark_email_read,
                                                            color: Colors.white,
                                                            size: 20,
                                                          )
                                                        : const Icon(
                                                            Icons.mail_outline,
                                                            color: Colors.grey,
                                                            size: 20,
                                                          ),
                                                  ),
                                                ),
                                                                                                                                                title: Text(
                                                                                                                                                  attendee.name,
                                                                                                                                                  style: TextStyle(
                                                                                                                                                    fontSize: 16,
                                                                                                                                                    fontWeight: FontWeight.bold,
                                                                                                                                                    color: Theme.of(context)
                                                                                                                                                        .primaryColor,
                                                                                                                                                  ),
                                                                                                                                                  overflow:
                                                                                                                                                      TextOverflow.ellipsis,
                                                                                                                                                ),
                                                                                                                                                subtitle: Column(
                                                                                                                                                  crossAxisAlignment:
                                                                                                                                                      CrossAxisAlignment.start,
                                                                                                                                                  children: [
                                                                                                                                                    Text(
                                                                                                                                                      attendee.address,
                                                                                                                                                      style: const TextStyle(
                                                                                                                                                          fontSize: 10),
                                                                                                                                                    ),
                                                                                                                                                    if (attendee
                                                                                                                                                        .email.isNotEmpty)
                                                                                                                                                      Text(
                                                                                                                                                        attendee.email,
                                                                                                                                                        style: TextStyle(
                                                                                                                                                          fontSize: 10,
                                                                                                                                                          color:
                                                                                                                                                              Theme.of(context)
                                                                                                                                                                  .primaryColor,
                                                                                                                                                          fontWeight:
                                                                                                                                                              FontWeight.w500,
                                                                                                                                                        ),
                                                                                                                                                      ),
                                                                                                                                                                                                                                                            Row(
                                                                                                                                                                                                                                                              children: [
                                                                                                                                                                                                                                                                if (attendee.forumDate !=
                                                                                                                                                                                                                                                                    null)
                                                                                                                                                                                                                                                                  Text(
                                                                                                                                                                                                                                                                    '${attendee.type} Forum: ${DateFormat('MMM dd, yyyy').format(attendee.forumDate!)}',
                                                                                                                                                                                                                                                                    style: TextStyle(
                                                                                                                                                                                                                                                                      fontSize: 9,
                                                                                                                                                                                                                                                                      color: Colors
                                                                                                                                                                                                                                                                          .grey[600],
                                                                                                                                                                                                                                                                      fontWeight:
                                                                                                                                                                                                                                                                          FontWeight
                                                                                                                                                                                                                                                                              .bold,
                                                                                                                                                                                                                                                                    ),
                                                                                                                                                                                                                                                                  ),
                                                                                                                                                                                                                                                                if (attendee.emailSentDate !=
                                                                                                                                                                                                                                                                    null) ...[                                                                                                                                                                                                              const SizedBox(
                                                                                                                                                                                                                  width: 8),
                                                                                                                                                                                                              Text(
                                                                                                                                                                                                                '• Sent: ${DateFormat('MMM dd, yyyy').format(attendee.emailSentDate!)}',
                                                                                                                                                                                                                style:
                                                                                                                                                                                                                    const TextStyle(
                                                                                                                                                                                                                  fontSize: 9,
                                                                                                                                                                                                                  color:
                                                                                                                                                                                                                      Colors.green,
                                                                                                                                                                                                                  fontWeight:
                                                                                                                                                                                                                      FontWeight
                                                                                                                                                                                                                          .bold,
                                                                                                                                                                                                                ),
                                                                                                                                                                                                              ),
                                                                                                                                                                                                            ],
                                                                                                                                                                                                          ],
                                                                                                                                                                                                        ),                                                                                                                                                  ],
                                                                                                                                                ),                                                trailing: isAuthorized
                                                    ? IconButton(
                                                        icon: Icon(
                                                          Icons.edit_note,
                                                          color:
                                                              Theme.of(context)
                                                                  .primaryColor,
                                                        ),
                                                        onPressed: () {
                                                          _showForumAttendeeFormWithEdit(
                                                              attendee);
                                                        },
                                                        tooltip: 'Edit',
                                                      )
                                                    : null,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
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
              // Positioned FAB column
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                    if (role == 'Developer') ...[
                                      FloatingActionButton(
                                        mini: true,
                                        heroTag: 'markAllSentForumCert',
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text('Mark All as Sent?'),
                                              content: const Text(
                                                  'This will mark all unsent certificates as "Sent" using today\'s date. No emails will be sent.'),
                                              actions: [
                                                TextButton(
                                                  onPressed: () => Navigator.pop(context),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                    _markAllAsSent();
                                                  },
                                                  child: const Text('Mark All'),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                        backgroundColor: Colors.white,
                                        tooltip: 'Mark All as Sent',
                                        child: const Icon(Icons.done_all,
                                            color: Colors.deepPurple),
                                      ),
                                      const SizedBox(height: 10),
                                    ],
                                    FloatingActionButton(
                                      mini: true,
                                      heroTag: 'sendAllForumCert',
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Send All Unsent?'),
                                            content: const Text(
                                                'This will generate and send certificates to all recipients who have an email address but haven\'t received theirs yet.'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                  _sendAllUnsent();
                                                },
                                                child: const Text('Send All'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      backgroundColor: Colors.white,
                                      child: const Icon(Icons.forward_to_inbox,
                                          color: Colors.deepPurple),
                                    ),
                                    const SizedBox(height: 10),
                                    FloatingActionButton(
                                      mini: true,
                                      heroTag: 'importForumCert',
                                      onPressed: _importCSV,
                                      backgroundColor: Colors.white,
                                      tooltip: 'Import CSV',
                                      child: const Icon(Icons.upload_file,
                                          color: Colors.deepPurple),
                                    ),
                                    const SizedBox(height: 10),
                                    FloatingActionButton(
                                      mini: true,
                                      heroTag: 'scanQRForumCert',
                                      onPressed: _scanQRCode,
                                      backgroundColor: Colors.white,
                                      child: const Icon(Icons.qr_code_scanner,
                                          color: Colors.deepPurple),
                                    ),
                                  ],
                                ),
                              ),
            ],
          ),
        );
      },
    );
  }
}
