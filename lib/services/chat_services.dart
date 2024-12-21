import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:symphonix/pages/Models/Message.dart';

class ChatServices extends ChangeNotifier {
  FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
//Send message to chat room
  Future<void> sendMessage(String reciverId, String message) async {
    final String currentUid = _firebaseAuth.currentUser!.uid;
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
      senderId: currentUid,
      reciverId: reciverId,
      message: message,
      timestamp: timestamp,
    );

    List<String> ids = [currentUid, reciverId];
    ids.sort();
    String ChatRoomId = ids.join('_');

    await _firestore
        .collection('chat_rooms')
        .doc(ChatRoomId)
        .collection('messages')
        .add(newMessage.toMap());
  }

  //Get all messages from chat room
  Stream<QuerySnapshot> getMessages(String UserId, String itherUserId) {
    List<String> ids = [UserId, itherUserId];
    ids.sort();
    String ChatRoomId = ids.join('_');

    return _firestore
        .collection('chat_rooms')
        .doc(ChatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }
}
