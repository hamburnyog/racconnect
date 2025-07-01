import 'dart:async';

import 'package:racconnect/data/models/user_model.dart';
import 'package:racconnect/utility/pocketbase_client.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthRepository {
  final pb = PocketBaseClient.instance;
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await pb
          .collection('users')
          .authWithPassword(email, password, expand: 'profile.section');

      if (response.record.data.isNotEmpty) {
        final isVerified = response.record.getBoolValue('verified');

        if (!isVerified) {
          throw 'Your account is inactive. Kindly check your email for the verification link or contact your administrator.';
        }
      }

      return UserModel.fromMap(response.record.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> signInWithGoogle() async {
    try {
      final response = await pb.collection('users').authWithOAuth2('google', (
        url,
      ) async {
        await launchUrl(url);
      }, expand: 'profile.section');

      if (response.record.data.isNotEmpty) {
        final isVerified = response.record.getBoolValue('verified');

        if (!isVerified) {
          throw 'Your account is inactive. Kindly check your email for the verification link or contact your administrator.';
        }
      }
      return UserModel.fromMap(response.record.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<void> requestPasswordReset({required String email}) async {
    try {
      await pb.collection('users').requestPasswordReset(email);
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
    required String name,
  }) async {
    try {
      final body = <String, dynamic>{
        "password": password,
        "passwordConfirm": passwordConfirm,
        "email": email,
        "name": name,
      };
      await pb.collection('users').create(body: body);
      await pb.collection('users').requestVerification(email);
    } catch (e) {
      rethrow;
    }
  }
}
