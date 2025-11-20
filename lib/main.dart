import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'auth_gate.dart';
import 'firebase_options.dart';
import 'package:medigen/services/mongo_service.dart'; // 1. Added import

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MediGenApp());
}

class MediGenApp extends StatelessWidget {
  MediGenApp({super.key});

  // Create the initialization Future
  final Future<void> _initialization = _initializeDependencies();

  // 2. Added this function to initialize BOTH Firebase and MongoDB
  static Future<void> _initializeDependencies() async {
    // Initialize Firebase
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // Initialize MongoDB
    // This will print "Connected" or an error to the console
    await MongoService.connect();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MediGen',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.teal).copyWith(
          secondary: Colors.tealAccent,
          background: Colors.grey[100],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,

      // We use a FutureBuilder to wait for initialization
      home: FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {

          // 1. If there's an error
          if (snapshot.hasError) {
            // We can log the error but maybe still show the app if Firebase worked
            // For now, let's show the error screen for safety
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text('Error initializing app: ${snapshot.error}'),
                ),
              ),
            );
          }

          // 2. If it's finished, show the AuthGate
          if (snapshot.connectionState == ConnectionState.done) {
            return const AuthGate();
          }

          // 3. While it's loading, show a loading circle
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }
}