import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:symphonix/services/chat_services.dart';

class YoutubeStreamingPage extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String selectedStreamingService;
  const YoutubeStreamingPage(
      {super.key,
      required this.roomId,
      required this.roomName,
      required this.selectedStreamingService});

  @override
  State<YoutubeStreamingPage> createState() => _YoutubeStreamingPageState();
}

class _YoutubeStreamingPageState extends State<YoutubeStreamingPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatServices _chatServices = ChatServices();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.roomName}\'s Room'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
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
}
