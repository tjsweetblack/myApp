import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      // Add Directionality widget
      textDirection: TextDirection.ltr, // Set text direction (usually ltr)
      child: Scaffold(
        // Or whatever your SplashScreen's root widget is
        body: Center(
          // Example content
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo/logo.png'), // Your logo
              const SizedBox(height: 16),
              const CircularProgressIndicator(), // Or your loading indicator
            ],
          ),
        ),
      ),
    );
  }
}
