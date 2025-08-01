import 'package:auth_bloc/helpers/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../logic/cubit/auth_cubit.dart';
import '../../../routing/routes.dart';
import '../../../theming/styles.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set background color to black
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) async {
          if (state is AuthLoading) {
            showLoadingDialog(context);
          } else if (state is AuthError) {
            Navigator.pop(context);
            showErrorDialog(context, state.message);
          } else if (state is UserSignIn) {
            Navigator.pop(context);
            Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.mainScreen,
              (route) => false,
            );
          } else if (state is UserSingupButNotVerified) {
            Navigator.pop(context);
            showInfoDialog(
              context,
              'Sign up Success',
              'Don\'t forget to verify your email. Check your inbox.',
            );
          }
        },
        builder: (context, state) {
          return _buildSignupPage(context);
        },
      ),
    );
  }

  Widget _buildSignupPage(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: SingleChildScrollView(
          // Wrap with SingleChildScrollView for smaller screens
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_add,
                  size: 80, color: Colors.white), // White Icon
              const SizedBox(height: 16),
              Text(
                "Create Account",
                style: TextStyles.font24Blue700Weight
                    .copyWith(fontSize: 24, color: Colors.white), // White title
              ),
              const SizedBox(height: 10),
              Text(
                "Sign up now and start exploring all that our app has to offer.",
                style: TextStyles.font14Grey400Weight.copyWith(
                    fontSize: 14, color: Colors.white70), // White subtitle
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                style: const TextStyle(
                    color: Colors.white), // Input text color white
                decoration: InputDecoration(
                  labelText: "Full Name",
                  labelStyle: const TextStyle(
                      color: Colors.white70), // Label text color white
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide:
                        const BorderSide(color: Colors.white54), // White border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(
                        color: Colors.white), // White focused border
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                style: const TextStyle(
                    color: Colors.white), // Input text color white
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  labelStyle: const TextStyle(
                      color: Colors.white70), // Label text color white
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide:
                        const BorderSide(color: Colors.white54), // White border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(
                        color: Colors.white), // White focused border
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                style: const TextStyle(
                    color: Colors.white), // Input text color white
                decoration: InputDecoration(
                  labelText: "Email",
                  labelStyle: const TextStyle(
                      color: Colors.white70), // Label text color white
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide:
                        const BorderSide(color: Colors.white54), // White border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(
                        color: Colors.white), // White focused border
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(
                    color: Colors.white), // Input text color white
                decoration: InputDecoration(
                  labelText: "Password",
                  labelStyle: const TextStyle(
                      color: Colors.white70), // Label text color white
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide:
                        const BorderSide(color: Colors.white54), // White border
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: const BorderSide(
                        color: Colors.white), // White focused border
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.read<AuthCubit>().signUpWithEmail(
                      nameController.text,
                      emailController.text,
                      passwordController.text,
                      phoneController.text);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(110.0)),
                  backgroundColor: Colors.white, // White button background
                  foregroundColor: Colors.black, // Black button text
                ),
                child: const Text(
                  "Sign Up",
                  style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold), // Black "Sign Up" text
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Already have an account? ",
                    style: TextStyle(
                        color: Colors
                            .white70), // White "Already have an account?" text
                  ),
                  GestureDetector(
                    onTap: () {
                      context.pushNamed(Routes.loginScreen);
                    },
                    child: Text(
                      "Sign In",
                      style: TextStyles.font14Blue400Weight.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // White "Sign In" text
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
        ), // White loading indicator
      ),
    );
  }

  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900], // Darker background for dialog
        title: const Text(
          'Error',
          style: TextStyle(color: Colors.white),
        ), // White title
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ), // White message
        actions: [
          TextButton(
            onPressed: () {
              context.pushNamed(Routes.loginScreen);
            },
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ), // White OK button
          ),
        ],
      ),
    );
  }

  void showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900], // Darker background for dialog
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ), // White title
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ), // White message
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ), // White OK button
          ),
        ],
      ),
    );
  }
}
