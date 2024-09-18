import 'package:coffee_shop/credenials/signup.dart';
import 'package:coffee_shop/main.dart';
import 'package:flutter/material.dart';

// ignore: depend_on_referenced_packages
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          margin: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _header(context),
              _inputField(context),
              _forgotPassword(context),
              _signup(context),
            ],
          ),
        ),
      ),
    );
  }

  _header(context) {
    return const Column(
      children: [
        Text(
          "Vamos Comer?!!",
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
        ),
        Text("Faça o login para continuar",),
      ],
    );
  }

  _inputField(context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          decoration: InputDecoration(
              hintText: "Username",
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none
              ),
              fillColor: const Color.fromARGB(255, 223, 115, 15).withOpacity(0.1),
              filled: true,
              prefixIcon: const Icon(Icons.person)),
        ),
        const SizedBox(height: 10),
        TextField(
          decoration: InputDecoration(
            hintText: "Password",
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none),
              fillColor: const Color.fromARGB(255, 223, 115, 15).withOpacity(0.1),
            filled: true,
            prefixIcon: const Icon(Icons.password),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute<void>(
      builder: (BuildContext context) => const CoffeeApp(),));
          },
          style: ElevatedButton.styleFrom(
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.amber,
          ),
          child: const Text(
            "Login",
            style: TextStyle(fontSize: 20
            ,color: Color.fromARGB(255, 49, 49, 49)),
          ),
        )
      ],
    );
  }

  _forgotPassword(context) {
    return TextButton(
      onPressed: () {},
      child: const Text("Forgot password?",
        style: TextStyle(color: Color.fromARGB(226, 223, 116, 15)),
      ),
    );
  }

  _signup(context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Dont have an account? "),
        TextButton(
            onPressed: () {
               Navigator.push(context, MaterialPageRoute<void>(
      builder: (BuildContext context) => const SignupPage(),));
            },
            child: const Text("Sign Up", style: TextStyle(color: Color.fromARGB(226, 223, 116, 15)),)
        )
      ],
    );
  }
}