import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SearchProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance; // Firestore instance
  Future<List<Map<String, dynamic>>> searchUsers(String searchText) async {
    String currentUserid = _auth.currentUser!.uid;
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: searchText)
          .where('username', isLessThan: searchText + '\uf8ff')
          .where(FieldPath.documentId, isNotEqualTo: currentUserid)
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print("Error searching users: $e");
      return [];
    }
  }

  Future<void> sendFriendRequest(String receiverUid) async {
    try {
      // Get the current user's UID
      String senderUid = _auth.currentUser!.uid;

      // Add sender UID to the receiver's 'friendRequests' array
      await _firestore.collection('users').doc(receiverUid).update({
        'friendRequests': FieldValue.arrayUnion([senderUid]),
      });

      print("Friend request sent successfully!");
    } catch (e) {
      print("Error sending friend request: $e");
    }
  }

  List<Map<String, dynamic>> _friendRequests = [];
  List<Map<String, dynamic>> get friendRequests => _friendRequests;

  Future<void> fetchFriendRequests() async {
    try {
      String currentUid = _auth.currentUser!.uid;

      // Fetch the user's document
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUid).get();

      // Extract friend requests
      List<dynamic> requests = userDoc['friendRequests'] ?? [];

      // Fetch details of each requester
      List<Map<String, dynamic>> requestDetails = [];
      for (String uid in requests) {
        DocumentSnapshot requesterDoc =
            await _firestore.collection('users').doc(uid).get();

        if (requesterDoc.exists) {
          requestDetails.add({
            'uid': uid,
            'username': requesterDoc['username'],
            'email': requesterDoc['email'],
          });
        }
      }

      _friendRequests = requestDetails;
      print(requestDetails);
      notifyListeners();
    } catch (e) {
      print("Error fetching friend requests: $e");
    }
  }

  Future<void> acceptFriendRequest(String requesterUid) async {
    try {
      String currentUid = _auth.currentUser!.uid;

      // Add requester to current user's friends list
      await _firestore.collection('users').doc(currentUid).update({
        'friends': FieldValue.arrayUnion([requesterUid]),
        'friendRequests': FieldValue.arrayRemove([requesterUid]),
      });

      // Add current user to requester's friends list
      await _firestore.collection('users').doc(requesterUid).update({
        'friends': FieldValue.arrayUnion([currentUid]),
      });
      await fetchFriendRequests();

      print("Friend request accepted!");
    } catch (e) {
      print("Error accepting friend request: $e");
    }
  }

  Future<void> declineFriendRequest(String requesterUid) async {
    try {
      String currentUid = _auth.currentUser!.uid;

      // Remove requester from friendRequests array
      await _firestore.collection('users').doc(currentUid).update({
        'friendRequests': FieldValue.arrayRemove([requesterUid]),
      });
      await fetchFriendRequests();
      print("Friend request declined!");
    } catch (e) {
      print("Error declining friend request: $e");
    }
  }
}
