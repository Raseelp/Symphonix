import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:symphonix/services/chat_services.dart';

class RoomChatPage extends StatefulWidget {
  final String roomId;
  final String roomName;
  const RoomChatPage({super.key, required this.roomId, required this.roomName});

  @override
  State<RoomChatPage> createState() => _RoomChatPageState();
}

class _RoomChatPageState extends State<RoomChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatServices _chatServices = ChatServices();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final storage = FlutterSecureStorage();

  void _sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatServices.sendMessage(
        roomId: widget.roomId,
        message: _messageController.text,
      );
      _messageController.clear();
    }
  }

  @override
  void initState() {
    Timer.periodic(Duration(seconds: 1), (timer) async {
      final roomSnapshot = await FirebaseFirestore.instance
          .collection('song_rooms')
          .doc(widget.roomId)
          .get();
      if (_firebaseAuth.currentUser!.uid == roomSnapshot.data()?['leader']) {
        updateCurrentSong(widget.roomId);
      } else {
        print('User Is Not Leader');
      }
      if (roomSnapshot.exists) {
        final roomData = roomSnapshot.data();
        displaySongDetails(roomData!);
      } else {
        print('Room not found');
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.roomName}\'s Room'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: _buildmessageList(),
            ),
            buildMessageInput()
          ],
        ),
      ),
    );
  }

  Widget buildMessageInput() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter a message',
              ),
            ),
          ),
        ),
        IconButton(
            onPressed: _sendMessage,
            icon: const Icon(
              Icons.send,
              size: 30,
            ))
      ],
    );
  }

  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;

    var alignment = (data['senderId'] == _firebaseAuth.currentUser!.uid)
        ? Alignment.centerRight
        : Alignment.centerLeft;
    return Container(
      alignment: alignment,
      child: SelectableText(data['message']),
    );
  }

  Widget _buildmessageList() {
    return StreamBuilder(
      stream: _chatServices.getMessages(
        roomId: widget.roomId,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          children: snapshot.data!.docs
              .map((document) => _buildMessageItem(document))
              .toList(),
        );
      },
    );
  }

  void updateCurrentSong(String roomId) async {
    final accessToken = await storage.read(key: 'spotify_token');
    final response = await http.get(
      Uri.parse('https://api.spotify.com/v1/me/player/currently-playing'),
      headers: {
        'Authorization':
            'Bearer $accessToken', // Replace with your access token.
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final songDetails = {
        'songName': data['item']['name'],
        'artistName': (data['item']['artists'] as List)
            .map((artist) => artist['name'])
            .join(', '),
        'songURI': data['item']['uri'],
        'playbackTimestamp': data['progress_ms'],
        'playbackStatus': data['is_playing'] ? 'playing' : 'paused',
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      };

      FirebaseFirestore.instance
          .collection('song_rooms')
          .doc(roomId)
          .set(songDetails, SetOptions(merge: true));
    } else {
      print('Failed to fetch currently playing song: ${response.body}');
    }
  }

  void displaySongDetails(Map<String, dynamic> roomData) {
    print('Song: ${roomData['songName']}');
    print('Artist: ${roomData['artistName']}');
    print('Status: ${roomData['playbackStatus']}');
  }
}
