import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class userAuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Firestore instance

  // Register User and Store in Firestore
  Future<String?> registerUser({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      // Step 1: Register User in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = result.user!.uid; // Get UID from Firebase Auth

      // Step 2: Save User Details to Firestore (users collection)
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'username': username,
      });

      // Step 3: Return null if success
      return null;
    } catch (e) {
      // Return error message in case of failure
      return e.toString();
    }
  }

  // Store the user data (email, username, etc.) in a class variable
  String _email = '';
  String _username = '';
  String get email => _email;
  String get username => _username;

  // Fetch user details from Firestore by UID (this is reusable)
  Future<void> fetchUserDetails(String uid) async {
    try {
      // Fetch user data from Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      // If user data exists, update the local variables
      if (userDoc.exists) {
        _email = userDoc['email'];
        _username = userDoc['username'];
      }

      // Notify listeners about the change in user details
      notifyListeners();
    } catch (e) {
      print("Error fetching user details: $e");
      // Handle error appropriately
    }
  }

  // Login Function
  Future<String?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // Step 1: Authenticate the user with Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid =
          userCredential.user!.uid; // Get UID of the authenticated user

      // Step 2: Fetch user details from Firestore
      await fetchUserDetails(uid);

      // Step 3: Return null if login is successful
      return null;
    } catch (e) {
      // Return error message if login fails
      return e.toString();
    }
  }

  Future<void> logoutUser() async {
    await FirebaseAuth.instance.signOut();

    notifyListeners();
  }
}
