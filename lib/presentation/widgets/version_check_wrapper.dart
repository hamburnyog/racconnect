import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:racconnect/logic/cubit/version_check_cubit.dart';
import 'package:racconnect/presentation/widgets/update_notification_banner.dart';

class VersionCheckWrapper extends StatelessWidget {
  const VersionCheckWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VersionCheckCubit, VersionCheckState>(
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
                  driveLink: state.driveLink,
                  onDismiss: () {
                    context.read<VersionCheckCubit>().dismissNotification();
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
