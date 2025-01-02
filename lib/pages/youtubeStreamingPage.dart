import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:symphonix/services/chat_services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final ChatServices _chatServices = ChatServices();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  List<Map<String, dynamic>> _videoSuggestions = [];
  String? _selectedVideoId;

  final YoutubePlayerController _youtubeController = YoutubePlayerController(
    initialVideoId: '',
    flags: const YoutubePlayerFlags(
      autoPlay: true,
      mute: false,
    ),
  );

  @override
  void dispose() {
    _searchController.dispose();
    _youtubeController.dispose();
    super.dispose();
  }

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
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search YouTube videos',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) _fetchSuggestions(value);
              },
            ),
          ),
          // Suggestions list
          if (_videoSuggestions.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _videoSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _videoSuggestions[index];
                  return ListTile(
                    leading: Image.network(suggestion['thumbnail']!),
                    title: Text(suggestion['title']!),
                    onTap: () {
                      _playVideo(suggestion['videoId']!);
                      setState(() {
                        _videoSuggestions.clear();
                      });
                    },
                  );
                },
              ),
            ),
          // YouTube Player
          if (_selectedVideoId != null)
            YoutubePlayer(
              controller: _youtubeController,
              showVideoProgressIndicator: true,
            ),
          // Message list and input
          Expanded(
            child: Column(
              children: [
                Expanded(child: _buildmessageList()),
                buildMessageInput(),
              ],
            ),
          ),
        ],
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

  Future<void> _fetchSuggestions(String query) async {
    try {
      final Dio dio = Dio();
      const apiKey =
          'AIzaSyARszKX1euq6F59FjRqKFJ-2bQUv_t2fzY'; //TODO:restrict it later
      final url =
          'https://www.googleapis.com/youtube/v3/search?part=snippet&q=$query&type=video&key=$apiKey';
      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final List suggestions = response.data['items'];
        setState(() {
          _videoSuggestions = suggestions.map((item) {
            final snippet = item['snippet'];
            return {
              'videoId': item['id']['videoId'],
              'title': snippet['title'],
              'thumbnail': snippet['thumbnails']['default']['url'],
            };
          }).toList();
        });
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
    }
  }

  void _playVideo(String videoId) {
    setState(() {
      _selectedVideoId = videoId;
      _youtubeController.load(videoId);
    });
  }
}
