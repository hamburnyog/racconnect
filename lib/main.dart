import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:racconnect/logic/cubit/attendance_cubit.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';
import 'package:racconnect/logic/cubit/event_cubit.dart';
import 'package:racconnect/logic/cubit/holiday_cubit.dart';
import 'package:racconnect/logic/cubit/internet_cubit.dart';
import 'package:racconnect/logic/cubit/leave_cubit.dart';
import 'package:racconnect/logic/cubit/profile_cubit.dart';
import 'package:racconnect/logic/cubit/section_cubit.dart';
import 'package:racconnect/logic/cubit/suspension_cubit.dart';
import 'package:racconnect/logic/cubit/time_check_cubit.dart';
import 'package:racconnect/logic/cubit/travel_cubit.dart';
import 'package:racconnect/presentation/router/app_router.dart';
// import 'package:racconnect/utility/app_bloc_observer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory(
      (await getApplicationDocumentsDirectory()).path,
    ),
  );

  // Bloc.observer = AppBlocObserver();

  runApp(MyApp(appRouter: AppRouter(), connectivity: Connectivity()));
}

class MyApp extends StatefulWidget {
  final Connectivity connectivity;
  final AppRouter appRouter;

  const MyApp({super.key, required this.connectivity, required this.appRouter});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ThemeData baseTheme = ThemeData();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<InternetCubit>(
          create: (context) => InternetCubit(connectivity: widget.connectivity),
        ),
        BlocProvider<AuthCubit>(create: (_) => AuthCubit()),
        BlocProvider<SectionCubit>(create: (_) => SectionCubit()),
        BlocProvider<HolidayCubit>(create: (_) => HolidayCubit()),
        BlocProvider<EventCubit>(create: (_) => EventCubit()),
        BlocProvider<AttendanceCubit>(create: (_) => AttendanceCubit()),
        BlocProvider<ProfileCubit>(create: (_) => ProfileCubit()),
        BlocProvider<SuspensionCubit>(create: (_) => SuspensionCubit()),
        BlocProvider<LeaveCubit>(create: (_) => LeaveCubit()),
        BlocProvider<TravelCubit>(create: (_) => TravelCubit()),
        BlocProvider<TimeCheckCubit>(create: (_) => TimeCheckCubit()),
      ],
      child: MaterialApp(
        title: 'Racconnect Client',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            elevation: 0,
            foregroundColor: Colors.black,
            scrolledUnderElevation: 0,
          ),
          textTheme: GoogleFonts.ubuntuMonoTextTheme(baseTheme.textTheme),
          inputDecorationTheme: InputDecorationTheme(
            contentPadding: const EdgeInsets.all(27),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade300, width: 3),
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(width: 3),
              borderRadius: BorderRadius.circular(10),
            ),
            border: OutlineInputBorder(
              borderSide: BorderSide(width: 3),
              borderRadius: BorderRadius.circular(10),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(width: 3, color: Colors.red),
              borderRadius: BorderRadius.circular(10),
            ),
            suffixIconConstraints: BoxConstraints(minHeight: 0, minWidth: 0),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              minimumSize: Size(double.infinity, 60),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          useMaterial3: true,
        ),
        onGenerateRoute: widget.appRouter.onGenerateRoute,
      ),
    );
  }
}
