import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipeee/common/utils/color.dart';
import 'package:recipeee/common/utils/utils.dart';
import 'package:recipeee/features/auth/controller/auth_controller.dart';
import 'package:recipeee/features/auth/screens/sign_up_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  static const String routeName = '/login-screen';
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
  }

  void login(){
    if (_formKey.currentState!.validate()) {
      ref.read(authControllerProvider).signInWithEmail(
            context: context,
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        elevation: 0,
        backgroundColor: backgroundColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(hintText: 'Email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      showSnackBar(context, 'Please enter your email');
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(hintText: 'Password'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      showSnackBar(context, 'Please enter your password');
                    }
                    return null;
                  },
                ),
                SizedBox(height: size.height / 2),
                SizedBox(
                  width: size.width / 1.2,
                  child: ElevatedButton(
                    onPressed: login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tabColor,
                      minimumSize: Size(double.infinity, 50),
                    ),
                    child: Text('Log In', style: TextStyle(color: blackColor)),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, SignUpScreen.routeName);
                  },
                  child: Text('Don\'t have an account? Sign up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
