part of 'signatory_cubit.dart';

abstract class SignatoryState {}

class SignatoryInitial extends SignatoryState {}

class SignatoryLoading extends SignatoryState {}

class SignatoryLoadSuccess extends SignatoryState {
  final List<SignatoryModel> signatories;
  SignatoryLoadSuccess(this.signatories);
}

class SignatoryError extends SignatoryState {
  final String message;
  SignatoryError(this.message);
}
