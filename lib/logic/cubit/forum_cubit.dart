import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:racconnect/data/models/forum_attendee.dart';
import 'package:racconnect/data/repositories/forum_repository.dart';

part 'forum_state.dart';

class ForumCubit extends Cubit<ForumState> {
  final ForumRepository _repository = ForumRepository();

  ForumCubit() : super(ForumInitial());

  Future<void> fetchAttendees({int? year}) async {
    try {
      emit(ForumLoading());
      final allAttendees = await _repository.getAttendees();
      final selectedYear = year ?? DateTime.now().year;
      final filteredAttendees = allAttendees.where((attendee) {
        if (attendee.forumDate == null) return false;
        return attendee.forumDate!.year == selectedYear;
      }).toList();
      emit(ForumLoaded(
        allAttendees: allAttendees,
        attendees: filteredAttendees,
        selectedYear: selectedYear,
      ));
    } catch (e) {
      emit(ForumError(message: e.toString()));
    }
  }

  void filterAttendeesByYear(int year) {
    if (state is ForumLoaded) {
      final currentState = state as ForumLoaded;
      final filteredAttendees = currentState.allAttendees.where((attendee) {
        if (attendee.forumDate == null) return false;
        return attendee.forumDate!.year == year;
      }).toList();
      emit(ForumLoaded(
        allAttendees: currentState.allAttendees,
        attendees: filteredAttendees,
        selectedYear: year,
      ));
    }
  }

  Future<void> addAttendee(ForumAttendee attendee) async {
    try {
      emit(ForumLoading());
      await _repository.addAttendee(attendee);
      emit(ForumAddSuccess());
    } catch (e) {
      emit(ForumError(message: e.toString()));
    }
  }

  Future<void> removeAttendee(String id) async {
    try {
      emit(ForumLoading());
      await _repository.deleteAttendee(id);
      emit(ForumDeleteSuccess());
    } catch (e) {
      emit(ForumError(message: e.toString()));
    }
  }

  Future<void> updateAttendee(String id, ForumAttendee attendee,
      {bool silent = false}) async {
    try {
      if (!silent) emit(ForumLoading());
      await _repository.updateAttendee(id, attendee);
      if (silent) {
        emit(ForumUpdateSilentSuccess());
      } else {
        emit(ForumUpdateSuccess());
      }
    } catch (e) {
      emit(ForumError(message: e.toString()));
    }
  }
}
