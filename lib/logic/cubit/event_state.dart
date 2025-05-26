part of 'event_cubit.dart';

sealed class EventState {
  const EventState();
}

final class EventInitial extends EventState {}

final class EventLoading extends EventState {}

final class EventError extends EventState {
  final String error;
  const EventError(this.error);
}

final class GetAllEventSuccess extends EventState {
  final Map<String, List> events;
  const GetAllEventSuccess(this.events);
}
