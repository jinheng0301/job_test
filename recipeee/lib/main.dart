import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipeee/common/utils/color.dart';
import 'package:recipeee/common/utils/loader.dart';
import 'package:recipeee/common/widgets/error.dart';
import 'package:recipeee/features/auth/controller/auth_controller.dart';
import 'package:recipeee/features/auth/screens/login_screen.dart';
import 'package:recipeee/firebase_options.dart';
import 'package:recipeee/models/user_model.dart';
import 'package:recipeee/router.dart';
import 'package:recipeee/features/recipe/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Recipeee',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: backgroundColor,
        appBarTheme: const AppBarTheme(color: appBarColor),
      ),
      onGenerateRoute: (settings) => onGenerateRoute(settings),
      home: ref
          .watch(authStateProvider)
          .when(
            loading: () => const Loader(),
            error: (err, trace) => ErrorScreen(error: err.toString()),
            data: (User? user) {
              if (user == null) {
                return LoginScreen();
              }

              return ref
                  .watch(userDataAuthProvider)
                  .when(
                    loading: () => const Loader(),
                    error: (err, trace) => ErrorScreen(error: err.toString()),
                    data: (UserModel? userData) {
                      if (userData == null) {
                        return LoginScreen();
                      }

                      print(
                        '🔑 CurrentUser UID = ${FirebaseAuth.instance.currentUser?.uid}',
                      );
                      print(
                        '🔑 CurrentUser username = ${FirebaseAuth.instance.currentUser?.displayName}',
                      );

                      return HomeScreen();
                    },
                  );
            },
          ),
    );
  }
}
