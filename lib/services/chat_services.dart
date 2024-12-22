import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:symphonix/pages/Models/Message.dart';

class ChatServices extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send message (works for both direct and room messages)
  Future<void> sendMessage({
    String? reciverId,
    String? roomId,
    required String message,
  }) async {
    final String currentUid = _firebaseAuth.currentUser!.uid;
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
      senderId: currentUid,
      reciverId,
      roomId,
      message: message,
      timestamp: timestamp,
    );

    if (roomId != null) {
      // Room message
      await _firestore
          .collection('chat_rooms')
          .doc(roomId)
          .collection('messages')
          .add(newMessage.toMap());
    } else if (reciverId != null) {
      // Direct message
      List<String> ids = [currentUid, reciverId];
      ids.sort();
      String chatRoomId = ids.join('_');

      await _firestore
          .collection('direct_chats')
          .doc(chatRoomId)
          .collection('messages')
          .add(newMessage.toMap());
    }
  }

  // Get messages stream
  Stream<QuerySnapshot> getMessages({String? userId, String? roomId}) {
    if (roomId != null) {
      // Room messages
      return _firestore
          .collection('chat_rooms')
          .doc(roomId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots();
    } else if (userId != null) {
      // Direct messages
      List<String> ids = [_firebaseAuth.currentUser!.uid, userId];
      ids.sort();
      String chatRoomId = ids.join('_');

      return _firestore
          .collection('direct_chats')
          .doc(chatRoomId)
          .collection('messages')
          .orderBy('timestamp', descending: false)
          .snapshots();
    }
    throw Exception('Either userId or roomId must be provided');
  }
}
