import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String senderId;
  final String? reciverId;
  final String? roomid;
  final String message;
  final Timestamp timestamp;

  Message(this.roomid, this.reciverId,
      {required this.senderId, required this.message, required this.timestamp});

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'reciverId': reciverId,
      'roomid': roomid,
      'message': message,
      'timestamp': timestamp,
    };
  }
}
