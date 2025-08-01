import 'package:auth_bloc/helpers/extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../logic/cubit/auth_cubit.dart';
import '../../../routing/routes.dart';
import '../../../theming/styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Set background color to black
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthLoading) {
            showLoadingDialog(context);
          } else if (state is AuthError) {
            Navigator.pop(context);
            showErrorDialog(context, state.message);
          } else if (state is UserSignIn) {
            Navigator.pop(context);
            Navigator.pushNamedAndRemoveUntil(
              context,
              Routes.mainScreen, //change here
              (route) => false,
            );
          } else if (state is UserNotVerified) {
            Navigator.pop(context);
            showInfoDialog(
              context,
              'Email Not Verified',
              'Please check your email and verify your account.',
            );
          }
        },
        builder: (context, state) {
          return _buildLoginPage(context);
        },
      ),
    );
  }

  Widget _buildLoginPage(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        // Wrap with SingleChildScrollView
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo/logo.png',
                height: 200), // Replace with your logo path
            const SizedBox(height: 16),
            Text(
              "Please enter your e-mail address\nand enter password",
              textAlign: TextAlign.center,
              style: TextStyles.font16Grey500Weight.copyWith(
                  fontSize: 16, color: Colors.white), // Set text color to white
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              style: const TextStyle(
                  color: Colors.white), // Input text color white
              decoration: InputDecoration(
                labelText: "Enter your email",
                labelStyle: const TextStyle(
                    color: Colors.white70), // Label text color white
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0), // Rounded corners
                  borderSide:
                      const BorderSide(color: Colors.white54), // White border
                ),
                focusedBorder: OutlineInputBorder(
                  // White focused border
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(
                  color: Colors.white), // Input text color white
              decoration: InputDecoration(
                labelText: "Enter your password",
                labelStyle: const TextStyle(
                    color: Colors.white70), // Label text color white
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0), // Rounded corners
                  borderSide:
                      const BorderSide(color: Colors.white54), // White border
                ),
                focusedBorder: OutlineInputBorder(
                  // White focused border
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: const BorderSide(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  context.pushNamed(Routes.forgetScreen);
                }, // Add forgot password functionality
                child: const Text(
                  "Forgot password?",
                  style: TextStyle(
                      color: Colors.white70), // White forgot password text
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<AuthCubit>().signInWithEmail(
                      _emailController.text,
                      _passwordController.text,
                    );
              },
              style: ElevatedButton.styleFrom(
                  minimumSize:
                      const Size(double.infinity, 50), // Full width button
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(110.0), // Rounded corners
                  ),
                  backgroundColor: Colors.white, // Button background white
                  foregroundColor: Colors.black // Button text black
                  ),
              child: const Text(
                "Login",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold), // Button Login text black
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account?",
                  style: TextStyle(
                      color:
                          Colors.white70), // White "Don't have an account" text
                ),
                GestureDetector(
                  onTap: () {
                    context.pushNamed(Routes.signupScreen);
                  },
                  child: Text(
                    "Sign Up",
                    style: TextStyles.font14Blue400Weight.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // White "Sign Up" text
                    ),
                  ),
                ),
              ],
            ),
          ],
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
            onPressed: () {},
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
