import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:racconnect/data/models/attendance_model.dart';
import 'package:racconnect/data/repositories/attendance_repository.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';
import 'package:racconnect/presentation/pages/employee_view_page.dart';
import 'package:racconnect/utility/constants.dart';

String? getPocketBaseFileUrl(String? filename, String? recordId) {
  if (filename == null ||
      filename.isEmpty ||
      recordId == null ||
      recordId.isEmpty) {
    return null;
  }
  return '$serverUrl/api/files/_pb_users_auth_/$recordId/$filename';
}

class PersonnelPage extends StatefulWidget {
  const PersonnelPage({super.key});

  @override
  State<PersonnelPage> createState() => _PersonnelPageState();
}

class _PersonnelPageState extends State<PersonnelPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<AttendanceModel> _todayAttendance = [];
  final _attendanceRepository = AttendanceRepository();

  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().getUsers();
    _fetchTodayAttendance();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _fetchTodayAttendance() async {
    try {
      final attendance = await _attendanceRepository.getAllAttendanceToday();
      if (mounted) {
        setState(() {
          _todayAttendance = attendance;
        });
      }
    } catch (e) {
      // Handle error
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

    return RefreshIndicator(
      triggerMode: RefreshIndicatorTriggerMode.anywhere,
      onRefresh: () async {
        context.read<AuthCubit>().getUsers();
        _fetchTodayAttendance();
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
                    'Personnel',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    !isSmallScreen
                        ? 'Manage employee profiles here. Pull down to refresh.'
                        : 'Manage employee profiles here',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                  leading: Icon(Icons.people_alt_outlined, color: Colors.white),
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
                    hintText:
                        'Search by name, employee number, or section code',
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
                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  var users = [];
                  if (state is UsersLoading) {
                    return Column(
                      children: [
                        SizedBox(height: 30),
                        CircularProgressIndicator(),
                      ],
                    );
                  }

                  if (state is AuthError) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(state.error),
                          backgroundColor: Colors.red,
                        ),
                      );
                    });
                  }

                  if (state is GetAllUsersSuccess) {
                    final loggedInUser = state.user;
                    final loggedInUserRole = loggedInUser.role;
                    final loggedInUserSectionCode =
                        loggedInUser.profile?.sectionCode;

                    users = state.users
                        .where((user) => user.role != null && user.role!.isNotEmpty)
                        .toList();

                    if (loggedInUserRole == 'OIC' ||
                        loggedInUserRole == 'Developer' ||
                        loggedInUserRole == 'HR') {
                      // Show all users
                    } else if (loggedInUserRole == 'Unit Head') {
                      users = users
                          .where((user) =>
                              user.profile?.sectionCode ==
                              loggedInUserSectionCode)
                          .toList();
                    } else {
                      users = [];
                    }

                    if (_searchQuery.isNotEmpty) {
                      users = users
                          .where((user) {
                            final profile = user.profile;
                            if (profile == null) return false;
                            final fullName =
                                '${profile.firstName} ${profile.middleName} ${profile.lastName}'
                                    .toLowerCase();
                            final employeeNumber =
                                profile.employeeNumber?.toLowerCase() ?? '';
                            final sectionCode =
                                profile.sectionCode?.toLowerCase() ?? '';
                            return fullName.contains(_searchQuery) ||
                                employeeNumber.contains(_searchQuery) ||
                                sectionCode.contains(_searchQuery);
                          }).toList();
                    }

                    if (users.isNotEmpty) {
                      return Expanded(
                        child: Scrollbar(
                          controller: _scrollController,
                          thumbVisibility: true,
                          interactive: true,
                          child: ListView.builder(
                            physics: AlwaysScrollableScrollPhysics(),
                            scrollDirection: Axis.vertical,
                            controller: _scrollController,
                            itemCount: users.length,
                            itemBuilder: (context, index) {
                              final user = users[index];
                              final profileModel = user.profile;
                              if (profileModel == null) {
                                return const SizedBox.shrink();
                              }
                              final avatarUrl = getPocketBaseFileUrl(
                                user.avatar,
                                user.id,
                              );
                              final middleInitial =
                                  profileModel.middleName != null &&
                                          profileModel.middleName!.isNotEmpty
                                      ? ' ${profileModel.middleName![0]}.'
                                      : '';

                              final hasAttendance = _todayAttendance.any(
                                (att) =>
                                    att.employeeNumber ==
                                    profileModel.employeeNumber,
                              );

                              return Card(
                                elevation: 3,
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        Theme.of(context).primaryColor,
                                    backgroundImage:
                                        avatarUrl != null
                                            ? NetworkImage(avatarUrl)
                                            : null,
                                    child:
                                        avatarUrl == null
                                            ? const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                            )
                                            : null,
                                  ),
                                  title: Text(
                                    '${profileModel.lastName}, ${profileModel.firstName}$middleInitial'
                                        .toUpperCase(),
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Employee Number: ${profileModel.employeeNumber ?? 'N/A'}\nSection: ${profileModel.sectionCode ?? 'Not Assigned'}',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                  onTap: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      scrollControlDisabledMaxHeightRatio: 0.75,
                                      showDragHandle: true,
                                      useSafeArea: true,
                                      builder: (BuildContext builder) {
                                        return EmployeeViewPage(user: user);
                                      },
                                    );
                                  },
                                  trailing:
                                      hasAttendance
                                          ? Icon(
                                            Icons
                                                .broadcast_on_personal_outlined,
                                            color: Colors.green,
                                          )
                                          : null,
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
                            _searchQuery.isEmpty
                                ? 'No employee profiles found.'
                                : 'No profiles match your search.',
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
