// Stream provider that listens to Firebase Auth state changes
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipeee/features/auth/repository/auth_repository.dart';
import 'package:recipeee/models/user_model.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final authControllerProvider = Provider((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository: authRepository, ref: ref);
});

final userDataAuthProvider = FutureProvider((ref) {
  final authController = ref.watch(authControllerProvider);
  return authController.getUserData();
});

class AuthController {
  final AuthRepository authRepository;
  final Ref ref;

  AuthController({required this.authRepository, required this.ref});

  // get user data from firebase
  Future<UserModel?> getUserData() async {
    UserModel? user = await authRepository.getCurrentUserData();
    return user;
  }

  Future<void> signUpWithEmail({
    required BuildContext context,
    required WidgetRef ref,
    required String email,
    required String password,
    required String name,
    required File? profilePic,
  }) async {
    return await authRepository.signUpWithEmail(
      context: context,
      ref: ref,
      email: email,
      password: password,
      name: name,
      profilePic: profilePic,
    );
  }

  Future<void> signInWithEmail({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    return await authRepository.signInWithEmail(
      context: context,
      email: email,
      password: password,
    );
  }

  Stream<UserModel> userDataById(String userId) {
    return authRepository.userData(userId);
  }

  void setUserState(bool isOnline) {
    authRepository.setUserState(isOnline);
  }

  Future<void> signOut({required BuildContext context}) async {
    return await authRepository.signOut(context);
  }
}
