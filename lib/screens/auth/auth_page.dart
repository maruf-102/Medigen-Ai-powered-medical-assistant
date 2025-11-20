import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'signup_screen.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  // Initially, show the login screen
  bool showLoginScreen = true;

  // Method to toggle between screens
  void toggleScreens() {
    setState(() {
      showLoginScreen = !showLoginScreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginScreen) {
      return LoginScreen(showSignUpScreen: toggleScreens);
    } else {
      return SignUpScreen(showLoginScreen: toggleScreens);
    }
  }
}