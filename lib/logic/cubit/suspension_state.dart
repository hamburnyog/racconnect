part of 'suspension_cubit.dart';

sealed class SuspensionState {
  const SuspensionState();
}

final class SuspensionInitial extends SuspensionState {}

final class SuspensionLoading extends SuspensionState {}

final class SuspensionError extends SuspensionState {
  final String error;
  const SuspensionError(this.error);
}

final class GetAllSuspensionSuccess extends SuspensionState {
  final List<SuspensionModel> suspensionModels;
  const GetAllSuspensionSuccess(this.suspensionModels);
}

final class SuspensionAddSuccess extends SuspensionState {
  final SuspensionModel suspensionModel;
  const SuspensionAddSuccess(this.suspensionModel);
}

final class SuspensionUpdateSuccess extends SuspensionState {
  final SuspensionModel suspensionModel;
  const SuspensionUpdateSuccess(this.suspensionModel);
}

final class SuspensionDeleteSuccess extends SuspensionState {}
