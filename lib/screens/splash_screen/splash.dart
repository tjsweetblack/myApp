import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset( // Or your logo widget
          'assets/images/logo/logo.png', // Path to your logo
          height: 200, // Adjust height as needed
        ),
      ),
    );
  }
}