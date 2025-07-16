import 'package:flutter/material.dart';
import 'package:recipeee/common/widgets/error.dart';
import 'package:recipeee/features/auth/screens/login_screen.dart';
import 'package:recipeee/features/auth/screens/sign_up_screen.dart';

Route<dynamic> onGenerateRoute(RouteSettings settings) {
  switch (settings.name) {
    // SIGN-UP-SCREEN
    case SignUpScreen.routeName:
      return MaterialPageRoute(builder: (_) => SignUpScreen());

    // LOGIN-SCREEN
    case LoginScreen.routeName:
      return MaterialPageRoute(builder: (_) => LoginScreen());

    // ERROR SCREEN
    default:
      return MaterialPageRoute(
        builder:
            (_) =>
                Scaffold(body: ErrorScreen(error: 'This page doesn\'t exist.')),
      );
  }
}
