part of 'accomplishment_cubit.dart';

sealed class AccomplishmentState {}

final class AccomplishmentInitial extends AccomplishmentState {}

final class AccomplishmentLoading extends AccomplishmentState {}

final class AccomplishmentLoaded extends AccomplishmentState {
  final List<AccomplishmentModel> accomplishments;
  AccomplishmentLoaded(this.accomplishments);
}

final class AccomplishmentError extends AccomplishmentState {
  final String error;
  AccomplishmentError(this.error);
}
