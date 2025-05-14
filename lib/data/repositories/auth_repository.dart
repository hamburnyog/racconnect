import 'package:pocketbase/pocketbase.dart';
import 'package:racconnect/data/models/user_model.dart';
import 'package:racconnect/utility/constants.dart';

class AuthRepository {
  final pb = PocketBase(Uri.parse(serverUrl).toString());

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await pb
          .collection('users')
          .authWithPassword(email, password);

      if (response.record.data.isNotEmpty) {
        final isVerified = response.record.getBoolValue('verified');

        if (!isVerified) {
          throw 'Your account is inactive. Kindly check your email for the verification link or contact your administrator.';
        }
      }

      return UserModel.fromJson(response.record.toString());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      pb.authStore.clear();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String passwordConfirm,
    required String firstName,
    String? middleName,
    required String lastName,
  }) async {
    try {
      final body = <String, dynamic>{
        "password": password,
        "passwordConfirm": passwordConfirm,
        "email": email,
        "firstName": firstName,
        "middleName": middleName,
        "lastName": lastName,
      };
      await pb.collection('users').create(body: body);
      // await pb.collection('users').requestVerification(email);
    } catch (e) {
      rethrow;
      // throw e.toString();
    }
  }
}
