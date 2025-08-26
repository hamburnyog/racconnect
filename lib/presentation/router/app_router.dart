import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';
import 'package:racconnect/logic/cubit/internet_cubit.dart';
import 'package:racconnect/presentation/screens/disconnected_screen.dart';
import 'package:racconnect/presentation/screens/main_screen.dart';
import 'package:racconnect/presentation/screens/password_reset_screen.dart';
import 'package:racconnect/presentation/screens/sign_in_screen.dart';
import 'package:racconnect/presentation/screens/sign_up_screen.dart';

class AppRouter {
  Route? onGenerateRoute(RouteSettings routeSettings) {
    return MaterialPageRoute(
      builder: (context) {
        final internetState = context.watch<InternetCubit>().state;
        bool internetConnected = internetState is InternetConnected;
        if (!internetConnected) {
          return DisconnectedScreen();
        } else {
          switch (routeSettings.name) {
            case '/':
              return BlocConsumer<AuthCubit, AuthState>(
                listener: (context, state) {
                  if (state is AuthError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.error),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }

                  if (state is AuthSignedUp) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Account created successfully! Kindly verify your email or contact an administrator to activate your account.',
                        ),
                      ),
                    );
                    Navigator.of(context).pop();
                  }

                  if (state is AuthPasswordResetSent) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Password reset sent to your email address! If it doesn\'t arrive in a few minutes, request again or contact an administrator.',
                        ),
                      ),
                    );
                    Navigator.of(context).pop();
                  }
                },
                builder: (context, state) {
                  if (state is AuthenticatedState) {
                    return MainScreen();
                  }
                  return SignInScreen();
                },
              );
            case '/signup':
              return SignUpScreen();
            case '/forgot-password':
              return PasswordResetScreen();
            default:
              return DisconnectedScreen();
          }
        }
      },
    );
  }
}
