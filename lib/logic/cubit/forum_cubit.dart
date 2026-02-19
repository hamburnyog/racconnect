import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:racconnect/data/models/forum_attendee.dart';
import 'package:racconnect/data/repositories/forum_repository.dart';

part 'forum_state.dart';

class ForumCubit extends Cubit<ForumState> {
  final ForumRepository _repository = ForumRepository();

  ForumCubit() : super(ForumInitial());

  Future<void> fetchAttendees() async {
    try {
      emit(ForumLoading());
      final attendees = await _repository.getAttendees();
      emit(ForumLoaded(attendees: attendees));
    } catch (e) {
      emit(ForumError(message: e.toString()));
    }
  }

  Future<void> addAttendee(ForumAttendee attendee) async {
    try {
      await _repository.addAttendee(attendee);
      emit(ForumAddSuccess());
    } catch (e) {
      emit(ForumError(message: e.toString()));
    }
  }

  Future<void> removeAttendee(String id) async {
    try {
      await _repository.deleteAttendee(id);
      emit(ForumDeleteSuccess());
    } catch (e) {
      emit(ForumError(message: e.toString()));
    }
  }

  Future<void> updateAttendee(String id, ForumAttendee attendee) async {
    try {
      await _repository.updateAttendee(id, attendee);
      emit(ForumUpdateSuccess());
    } catch (e) {
      emit(ForumError(message: e.toString()));
    }
  }
}
