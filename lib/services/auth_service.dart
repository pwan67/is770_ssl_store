import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream of auth state/profile changes
  Stream<User?> get user => _auth.userChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      print('Sign in error: ${e.message}');
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential?> registerWithEmailAndPassword(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user document with role
      if (credential.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
          'email': email,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      return credential;
    } on FirebaseAuthException catch (e) {
      print('Register error: ${e.message}');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print('Sign out error: ${e.toString()}');
      return null;
    }
  }
}
