import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // -----------------------------------------------------------------
  // This is the correct constructor for v6
  // -----------------------------------------------------------------
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Sign in with Email & Password
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException {
      return null;
    }
  }

  // Sign up with Email & Password
  Future<UserCredential?> signUpWithEmail(
      String email, String password, String fullName) async {
    try {
      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'fullName': fullName,
        'email': email,
        'profilePicUrl': null,
        'createdAt': Timestamp.now(),
      });

      return userCredential;
    } on FirebaseAuthException {
      return null;
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // -----------------------------------------------------------------
      // This is the correct v6 implementation
      // -----------------------------------------------------------------
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      // -----------------------------------------------------------------

      // Once signed in, return the UserCredential
      UserCredential userCredential =
      await _auth.signInWithCredential(credential);

      // Check if this is a new user
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      // If the user doc doesn't exist, create it
      if (!userDoc.exists) {
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'fullName': userCredential.user!.displayName,
          'email': userCredential.user!.email,
          'profilePicUrl': userCredential.user!.photoURL,
          'createdAt': Timestamp.now(),
        });
      }

      return userCredential;
    } catch (e) {
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}