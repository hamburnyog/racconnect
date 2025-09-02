import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:racconnect/logic/cubit/wfh_cubit.dart';
import 'package:racconnect/presentation/widgets/mobile_button.dart';

class WfhBadge extends StatelessWidget {
  final VoidCallback? onTap;
  const WfhBadge({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width <= 700;

    return BlocProvider(
      create:
          (context) =>
              WfhCubit()
                ..getInitialWfhCount()
                ..subscribeToWfhUpdates(),
      child: BlocBuilder<WfhCubit, WfhState>(
        builder: (context, state) {
          final wfhCount = state is WfhLoaded ? state.wfhCount : 0;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              MobileButton(
                isSmallScreen: isSmallScreen,
                onPressed: onTap,
                icon: Icons.broadcast_on_personal_outlined,
                label: 'WFH',
              ),
              if (wfhCount > 0)
                Positioned(
                  right: isSmallScreen ? -4 : 8,
                  top: isSmallScreen ? -4 : 2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$wfhCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
