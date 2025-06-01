import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:racconnect/data/repositories/event_repository.dart';

part 'event_state.dart';

class EventCubit extends Cubit<EventState> {
  EventCubit() : super(EventInitial());
  final EventRepository eventRepository = EventRepository();

  Future<void> getAllEvents() async {
    try {
      emit(EventLoading());
      final eventModels = await eventRepository.getAllEvents();
      emit(GetAllEventSuccess(eventModels));
    } catch (e) {
      errorMessage(e);
    }
  }

  void errorMessage(dynamic e) {
    if (e.runtimeType == ClientException) {
      final message = e.response?['message'];
      emit(EventError(message?.toString() ?? 'Unknown error'));
    } else {
      emit(EventError(e.toString()));
    }
  }
}
