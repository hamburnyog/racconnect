part of 'forum_cubit.dart';

abstract class ForumState extends Equatable {
  const ForumState();

  @override
  List<Object> get props => [];
}

class ForumInitial extends ForumState {}

class ForumLoading extends ForumState {}

class ForumError extends ForumState {
  final String message;

  const ForumError({required this.message});

  @override
  List<Object> get props => [message];
}

class ForumLoaded extends ForumState {
  final List<ForumAttendee> attendees;

  const ForumLoaded({required this.attendees});

  @override
  List<Object> get props => [attendees];
}

class ForumAddSuccess extends ForumState {}

class ForumUpdateSuccess extends ForumState {}

class ForumDeleteSuccess extends ForumState {}
