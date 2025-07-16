import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipeee/common/repositories/common_firebase_storage_repository.dart';
import 'package:recipeee/common/utils/utils.dart';
import 'package:recipeee/features/auth/screens/login_screen.dart';
import 'package:recipeee/main.dart';
import 'package:recipeee/models/user_model.dart';

final authRepositoryProvider = Provider(
  (ref) => AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  ),
);

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  AuthRepository({required this.auth, required this.firestore});

  // Stream for auth state changes
  Stream<User?> get authStateChanges => auth.authStateChanges();

  Future<UserModel?> getCurrentUserData() async {
    if (auth.currentUser == null) return null;

    var userData =
        await firestore.collection('users').doc(auth.currentUser?.uid).get();

    UserModel? user;
    if (userData.data() != null) {
      user = UserModel.fromMap(userData.data()!);
    }

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
    try {
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;
      String photoUrl =
          'https://www.shutterstock.com/image-vector/donald-trump-president-united-states-260nw-2283642167.jpg';

      if (profilePic != null) {
        photoUrl = await ref
            .read(commonFirebaseStorageRepositoryProvider)
            .storeFileToFirebase('profilePic/$uid', profilePic);
      }

      // Create data map first
      Map<String, dynamic> userData = {
        'name': name,
        'email': email,
        'uid': uid,
        'profilePic': photoUrl,
      };

      // Save to Firebase using set with merge option
      await firestore
          .collection('users')
          .doc(uid)
          .set(userData, SetOptions(merge: true));

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MyApp()),
        (route) => false,
      );

      showSnackBar(context, 'User created successfully');
    } on FirebaseAuthException catch (e) {
      // More specific error handling
      String errorMessage = 'An error occurred during sign up';

      if (e.code == 'email-already-in-use') {
        errorMessage = 'This email is already registered';
      } else if (e.code == 'weak-password') {
        errorMessage = 'Password is too weak';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Email address is invalid';
      }

      showSnackBar(context, errorMessage);
    } catch (e) {
      showSnackBar(context, e.toString());
      return;
    }
  }

  Future<void> signInWithEmail({
    required BuildContext context,
    required String email,
    required String password,
  }) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MyApp()),
        (route) => false,
      );

      showSnackBar(context, 'User signed in successfully');
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred during sign in';

      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for this email';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Incorrect password';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Email address is invalid';
      } else if (e.code == 'user-disabled') {
        errorMessage = 'This account has been disabled';
      }

      showSnackBar(context, errorMessage);
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await auth.signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (route) => false,
      );

      showSnackBar(context, 'Log out successfully!');
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  Stream<UserModel> userData(String userId) {
    return firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((event) => UserModel.fromMap(event.data()!));
  }

  void setUserState(bool isOnline) async {
    try {
      await firestore.collection('users').doc(auth.currentUser!.uid).update({
        'isOnline': isOnline,
      });
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
