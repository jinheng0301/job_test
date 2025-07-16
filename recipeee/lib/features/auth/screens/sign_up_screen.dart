import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recipeee/common/utils/color.dart';
import 'package:recipeee/common/utils/utils.dart';
import 'package:recipeee/features/auth/controller/auth_controller.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  static const String routeName = '/sign-up-screen';
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  File? profilePic;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
  }

  void selectImage() async {
    profilePic = await pickImageFromGallery(context);
    setState(() {});
  }

  void signUp() {
    if (_formKey.currentState!.validate()) {
      ref
          .read(authControllerProvider)
          .signUpWithEmail(
            context: context,
            ref: ref,
            email: emailController.text.trim(),
            password: passwordController.text.trim(),
            name: nameController.text.trim(),
            profilePic: profilePic,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Sign Up'), backgroundColor: backgroundColor),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Stack(
                  children: [
                    profilePic != null
                        ? CircleAvatar(
                          backgroundImage: FileImage(profilePic!),
                          radius: 70,
                        )
                        : CircleAvatar(
                          backgroundImage: NetworkImage(
                            'https://www.shutterstock.com/image-vector/donald-trump-president-united-states-260nw-2283642167.jpg',
                          ),
                          radius: 70,
                        ),
                    Positioned(
                      child: IconButton(
                        onPressed: selectImage,
                        icon: Icon(Icons.add_a_photo),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(hintText: 'Name'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      showSnackBar(context, 'Please enter your name');
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
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
                  keyboardType: TextInputType.visiblePassword,
                  obscureText: true,
                  decoration: InputDecoration(hintText: 'Password'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      showSnackBar(context, 'Please enter your password');
                    }
                    if (value!.length < 6) {
                      showSnackBar(
                        context,
                        'Password must be at least 6 characters',
                      );
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tabColor,
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text('Sign Up', style: TextStyle(color: blackColor)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
