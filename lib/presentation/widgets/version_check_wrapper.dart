import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:racconnect/logic/cubit/auth_cubit.dart';
import 'package:racconnect/logic/cubit/version_check_cubit.dart';
import 'package:racconnect/presentation/widgets/update_notification_banner.dart';

class VersionCheckWrapper extends StatelessWidget {
  const VersionCheckWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthCubit, AuthState>(
          listener: (context, authState) {
            // Trigger version check when user signs out (changes from Authenticated to non-authenticated)
            if (authState is! AuthenticatedState) {
              // Only trigger if not already in loading state
              final versionCheckState = context.read<VersionCheckCubit>().state;
              if (versionCheckState is! VersionCheckLoading) {
                context.read<VersionCheckCubit>().checkVersion();
              }
            }
          },
        ),
      ],
      child: BlocConsumer<VersionCheckCubit, VersionCheckState>(
        listener: (context, state) {
          // Handle any side effects from the state changes if needed
          if (state is VersionCheckError) {
            // Optionally show an error message to the user
            // print('Version check error: ${state.error}');
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              child, // Main content
              if (state is VersionCheckOutdated)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: UpdateNotificationBanner(
                    publishedVersion: state.publishedVersion,
                    iosLink: state.iosLink,
                    androidLink: state.androidLink,
                    macLink: state.macLink,
                    windowsLink: state.windowsLink,
                    onDismiss: () {
                      context.read<VersionCheckCubit>().dismissNotification();
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
