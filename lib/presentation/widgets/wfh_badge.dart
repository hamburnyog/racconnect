import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:racconnect/logic/cubit/wfh_cubit.dart';

class WfhBadge extends StatelessWidget {
  final VoidCallback? onTap;
  const WfhBadge({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: BlocProvider(
        create:
            (context) =>
                WfhCubit()
                  ..getInitialWfhCount()
                  ..subscribeToWfhUpdates(),
        child: BlocBuilder<WfhCubit, WfhState>(
          builder: (context, state) {
            if (state is WfhLoaded) {
              return Badge(
                label: Text('${state.wfhCount}'),

                child: const Icon(
                  Icons.broadcast_on_personal_outlined,
                  color: Colors.white,
                ),
              );
            }
            return Badge(
              label: const Text('0'),
              child: const Icon(
                Icons.broadcast_on_personal_outlined,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }
}
