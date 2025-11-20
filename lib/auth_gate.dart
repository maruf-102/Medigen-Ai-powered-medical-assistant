import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'screens/auth/auth_page.dart';
import 'screens/home/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        // This stream listens for auth changes
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // 1. If the snapshot is still loading, show a progress indicator
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. If the snapshot has data (user is logged in)
          if (snapshot.hasData) {
            return const HomePage();
          }

          // 3. If the snapshot has no data (user is logged out)
          return const AuthPage();
        },
      ),
    );
  }
}