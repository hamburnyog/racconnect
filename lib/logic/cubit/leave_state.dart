part of 'leave_cubit.dart';

sealed class LeaveState {
  const LeaveState();
}

final class LeaveInitial extends LeaveState {}

final class LeaveLoading extends LeaveState {}

final class LeaveError extends LeaveState {
  final String error;
  const LeaveError(this.error);
}

final class GetAllLeaveSuccess extends LeaveState {
  final List<LeaveModel> leaveModels;
  const GetAllLeaveSuccess(this.leaveModels);
}

final class LeaveAddSuccess extends LeaveState {
  final LeaveModel leaveModel;
  const LeaveAddSuccess(this.leaveModel);
}

final class LeaveUpdateSuccess extends LeaveState {
  final LeaveModel leaveModel;
  const LeaveUpdateSuccess(this.leaveModel);
}

final class LeaveDeleteSuccess extends LeaveState {}
