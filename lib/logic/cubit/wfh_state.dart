part of 'wfh_cubit.dart';

abstract class WfhState extends Equatable {
  const WfhState();

  @override
  List<Object> get props => [];
}

class WfhInitial extends WfhState {}

class WfhLoading extends WfhState {}

class WfhLoaded extends WfhState {
  final int wfhCount;

  const WfhLoaded(this.wfhCount);

  @override
  List<Object> get props => [wfhCount];
}

class WfhError extends WfhState {
  final String message;

  const WfhError(this.message);

  @override
  List<Object> get props => [message];
}
