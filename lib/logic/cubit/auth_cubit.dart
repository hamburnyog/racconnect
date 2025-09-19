import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:racconnect/data/models/user_model.dart';
import 'package:racconnect/data/repositories/auth_repository.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());
  final authRepository = AuthRepository();

  void signOut() async {
    try {
      emit(AuthLoading());
      await authRepository.signOut();
      emit(AuthInitial());
    } catch (e) {
      errorMessage(e);
    }
  }

  void signUp({
    required String email,
    required String password,
    required String passwordConfirm,
    required String name,
  }) async {
    try {
      emit(AuthLoading());
      await authRepository.signUp(
        email: email,
        password: password,
        passwordConfirm: passwordConfirm,
        name: name,
      );
      emit(AuthSignedUp());
    } catch (e) {
      errorMessage(e);
    }
  }

  void signIn({required String email, required String password}) async {
    try {
      emit(AuthLoading());
      final userModel = await authRepository.signIn(
        email: email,
        password: password,
      );
      emit(AuthSignedIn(userModel));
    } catch (e) {
      errorMessage(e);
    }
  }

  void signInWithGoogle() async {
    try {
      final userModel = await authRepository.signInWithGoogle();
      emit(AuthSignedIn(userModel));
    } catch (e) {
      errorMessage(e);
    }
  }

  void requestPasswordReset(String email) async {
    try {
      emit(AuthLoading());
      await authRepository.requestPasswordReset(email: email);
      // Delaying to simulate a network request, to give the user an impression that the email is not instant
      await Future.delayed(const Duration(seconds: 3));
      emit(AuthPasswordResetSent());
    } catch (e) {
      errorMessage(e);
    }
  }

  void refreshUser(UserModel updatedUser) {
    emit(AuthSignedIn(updatedUser));
  }

  Future<void> refreshCurrentUser() async {
    try {
      final updatedUser = await authRepository.refreshCurrentUser();
      emit(AuthSignedIn(updatedUser));
    } catch (e) {
      errorMessage(e);
    }
  }

  void errorMessage(dynamic e) {
    if (e.runtimeType == ClientException) {
      if (e.response['data'] != null &&
          e.response['data'].isNotEmpty &&
          e.response['data']['email']?['code'] == 'validation_not_unique') {
        emit(AuthError('The email address is already taken.'));
      } else {
        final message = e.response['message']?.toString();
        if (message != null && message.isNotEmpty) {
          emit(AuthError(message));
        } else {
          emit(AuthError('An unknown error occurred.'));
        }
      }
    } else {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> getUsers() async {
    if (state is AuthenticatedState) {
      final user = (state as AuthenticatedState).user;
      try {
        emit(UsersLoading(user));
        final users = await authRepository.getUsers();
        emit(GetAllUsersSuccess(user, users));
      } catch (e) {
        errorMessage(e);
      }
    }
  }
}
