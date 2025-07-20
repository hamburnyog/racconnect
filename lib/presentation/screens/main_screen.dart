import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';
import 'package:racconnect/presentation/pages/attendance_page.dart';
import 'package:racconnect/presentation/pages/holiday_page.dart';
import 'package:racconnect/presentation/pages/home_page.dart';
import 'package:racconnect/presentation/pages/profile_page.dart';
import 'package:racconnect/presentation/pages/section_page.dart';
import 'package:racconnect/utility/constants.dart';
import 'package:google_fonts/google_fonts.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<BottomNavigationBarItem> sidebarItemMenu = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String? getPocketBaseFileUrl(String? filename, String? recordId) {
    if (filename == null ||
        filename.isEmpty ||
        recordId == null ||
        recordId.isEmpty) {
      return null;
    }
    return '$serverUrl/api/files/_pb_users_auth_/$recordId/$filename';
  }

  String getUserInitial(AuthState state) {
    if (state is AuthSignedIn) {
      String name = state.user.name;
      return name.isNotEmpty ? name[0].toUpperCase() : '';
    }
    return '';
  }

  Widget getAvatarWidget(BuildContext context) {
    final state = context.read<AuthCubit>().state;
    String? avatarUrl;

    if (state is AuthSignedIn) {
      avatarUrl = getPocketBaseFileUrl(state.user.avatar, state.user.id);
    }

    return avatarUrl != null && avatarUrl.isNotEmpty
        ? CircleAvatar(
          radius: 20,
          backgroundImage: NetworkImage(avatarUrl),
          onBackgroundImageError:
              (error, stackTrace) => CircleAvatar(
                radius: 20,
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(Icons.person, color: Colors.white, size: 24),
              ),
        )
        : CircleAvatar(
          radius: 20,
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.person, color: Colors.white, size: 24),
        );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isSmallScreen = width < 700;
    final bool isLargeScreen = width > 800;

    return Scaffold(
      key: _scaffoldKey,
      appBar:
          !isSmallScreen
              ? AppBar(
                elevation: 0,
                centerTitle: true,
                titleSpacing: 0,
                toolbarHeight: 70,
                backgroundColor: Colors.transparent,
                scrolledUnderElevation: 0.0,
                surfaceTintColor: Colors.transparent,
                leadingWidth: 200,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      getAvatarWidget(context),
                      const SizedBox(width: 8),
                      Flexible(
                        child: BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, state) {
                            String userName = 'User';
                            if (state is AuthSignedIn &&
                                state.user.name.isNotEmpty) {
                              userName = state.user.email;
                              userName = userName.split('@').first;
                            }
                            return Text(
                              userName,
                              style: GoogleFonts.aBeeZee(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      context.read<AuthCubit>().signOut();
                      Navigator.pushReplacementNamed(context, '/');
                    },
                    icon: const Icon(Icons.logout),
                  ),
                ],
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/logo_bp.png', width: 50),
                        const SizedBox(width: 20),
                        Column(
                          children: [
                            RichText(
                              text: TextSpan(
                                text: 'RACCO',
                                style: GoogleFonts.righteous(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: Theme.of(context).primaryColor,
                                ),
                                children: [
                                  TextSpan(
                                    text: 'nnect',
                                    style: GoogleFonts.righteous(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                      color: Theme.of(context).disabledColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              'Regional Child Care Office IV-A Calabarzon',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        Image.asset('assets/images/logo_nacc.png', width: 50),
                      ],
                    ),
                  ),
                ),
              )
              : AppBar(
                centerTitle: true,
                surfaceTintColor: Colors.transparent,
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/logo_bp.png', width: 40),
                    const SizedBox(width: 10),
                    Column(
                      children: [
                        RichText(
                          text: TextSpan(
                            text: 'RACCO',
                            style: GoogleFonts.righteous(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              color: Theme.of(context).primaryColor,
                            ),
                            children: [
                              TextSpan(
                                text: 'nnect',
                                style: GoogleFonts.righteous(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22,
                                  color: Theme.of(context).disabledColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'RACCO IV-A Calabarzon',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 10),
                    Image.asset('assets/images/logo_nacc.png', width: 40),
                  ],
                ),
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: getAvatarWidget(context),
                ),
                actions: [
                  IconButton(
                    onPressed: () {
                      context.read<AuthCubit>().signOut();
                      Navigator.pushReplacementNamed(context, '/');
                    },
                    icon: const Icon(Icons.logout),
                  ),
                ],
              ),
      bottomNavigationBar:
          isSmallScreen
              ? BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  sidebarItemMenu = sideBarItemsUser;
                  if (state is AuthSignedIn && state.user.role == 'Developer') {
                    sidebarItemMenu = sideBarItemsDev;
                  } else if (state is AuthSignedIn &&
                      state.user.role == 'OIC') {
                    sidebarItemMenu = sideBarItemsOic;
                  } else if (state is AuthSignedIn && state.user.role == 'HR') {
                    sidebarItemMenu = sideBarItemsHr;
                  } else if (state is AuthSignedIn &&
                      state.user.role == 'Records') {
                    sidebarItemMenu = sideBarItemsRecords;
                  }
                  return BottomNavigationBar(
                    items: sidebarItemMenu,
                    fixedColor: Colors.black,
                    unselectedItemColor: Colors.grey,
                    currentIndex: _selectedIndex,
                    onTap: (int index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  );
                },
              )
              : null,
      body: SafeArea(
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            sidebarItemMenu = sideBarItemsUser;
            if (state is AuthSignedIn && state.user.role == 'Developer') {
              sidebarItemMenu = sideBarItemsDev;
            } else if (state is AuthSignedIn && state.user.role == 'OIC') {
              sidebarItemMenu = sideBarItemsOic;
            } else if (state is AuthSignedIn && state.user.role == 'HR') {
              sidebarItemMenu = sideBarItemsHr;
            } else if (state is AuthSignedIn && state.user.role == 'Records') {
              sidebarItemMenu = sideBarItemsRecords;
            }
            return Row(
              children: <Widget>[
                if (!isSmallScreen)
                  NavigationRail(
                    selectedIndex: _selectedIndex,
                    onDestinationSelected: (int index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    extended: isLargeScreen,
                    destinations:
                        sidebarItemMenu
                            .map(
                              (item) => NavigationRailDestination(
                                icon: item.icon,
                                selectedIcon: item.activeIcon,
                                label: Text(item.label!),
                              ),
                            )
                            .toList(),
                  ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(color: Colors.white70, spreadRadius: 1),
                      ],
                    ),
                    child: Builder(
                      builder: (context) {
                        if (sidebarItemMenu[_selectedIndex].label == 'Home') {
                          return HomePage();
                        } else if (sidebarItemMenu[_selectedIndex].label ==
                            'Sections') {
                          return SectionPage();
                        } else if (sidebarItemMenu[_selectedIndex].label ==
                            'Holidays') {
                          return HolidayPage();
                        } else if (sidebarItemMenu[_selectedIndex].label ==
                            'Profile') {
                          return ProfilePage();
                        } else if (sidebarItemMenu[_selectedIndex].label ==
                            'Attendance') {
                          return AttendancePage();
                        } else {
                          return Text(
                            sidebarItemMenu[_selectedIndex].label.toString(),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
