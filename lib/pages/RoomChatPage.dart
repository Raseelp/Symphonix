import 'dart:async';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:symphonix/Providers/songProvider.dart';
import 'package:symphonix/services/chat_services.dart';
import 'package:url_launcher/url_launcher.dart';

class RoomChatPage extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String selectedStreamingService;
  const RoomChatPage(
      {super.key,
      required this.roomId,
      required this.roomName,
      required this.selectedStreamingService});

  @override
  State<RoomChatPage> createState() => _RoomChatPageState();
}

class _RoomChatPageState extends State<RoomChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ChatServices _chatServices = ChatServices();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final storage = FlutterSecureStorage();
  Timer? _timer;

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
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
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
        Provider.of<SongProvider>(context, listen: false)
            .updateSongDetails(roomData!);
        displaySongDetails(roomData);
      } else {
        print('Room not found');
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer when widget is disposed
    super.dispose();
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
            buildCurrentSongWidget(),
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

  Widget buildCurrentSongWidget() {
    return Consumer<SongProvider>(
      builder: (context, songProvider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              if (songProvider.albumArtUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    songProvider.albumArtUrl,
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 12),
              Text(
                songProvider.songName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                songProvider.artistName,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  songProvider.playbackStatus == 'playing'
                      ? const Text(
                          'Playing',
                          style: TextStyle(color: Colors.green),
                        )
                      : const Text('Paused',
                          style: TextStyle(color: Colors.redAccent)),
                  const SizedBox(width: 8),
                  Text(
                    '${(songProvider.playbackTimestamp / 1000).toStringAsFixed(1)}s',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  ElevatedButton(
                    onPressed: () => syncWithLeader(context, songProvider),
                    child: const Text('Sync with Leader'),
                  ),
                ],
              ),
            ],
          ),
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
        'albumArtUrl': data['item']['album']['images'][0]['url'] ?? '',
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
      // Set default values when no song is playing or request fails
      final songDetails = {
        'songName': 'No song playing',
        'artistName': '',
        'albumArtUrl': '',
        'songURI': '',
        'playbackTimestamp': 0,
        'playbackStatus': 'paused',
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('song_rooms')
          .doc(roomId)
          .set(songDetails, SetOptions(merge: true));

      print('Failed to fetch currently playing song: ${response.body}');
    }
  }

  void displaySongDetails(Map<String, dynamic> roomData) {
    print('Song: ${roomData['songName']}');
    print('Artist: ${roomData['artistName']}');
    print('Status: ${roomData['playbackStatus']}');
  }

  void syncWithLeader(BuildContext context, SongProvider songProvider) async {
    final songURI = songProvider.songURI;
    final timestamp = (songProvider.playbackTimestamp / 1000).toInt();

    if (songURI.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No song available to sync.')),
      );
      return;
    }

    try {
      // Create Spotify URI with position parameter
      final spotifyUri =
          Uri.parse('$songURI?position_ms=${songProvider.playbackTimestamp}');
      final canLaunchSpotify = await canLaunchUrl(spotifyUri);

      if (canLaunchSpotify) {
        await launchUrl(
          spotifyUri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        // Fallback to web URL with timestamp
        final trackId = songURI.split(':').last;
        final webUrl = Uri.parse(
            'https://open.spotify.com/track/$trackId?position_ms=${songProvider.playbackTimestamp}');

        if (await canLaunchUrl(webUrl)) {
          await launchUrl(
            webUrl,
            mode: LaunchMode.externalApplication,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Could not open Spotify. Please make sure Spotify is installed.')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error launching Spotify: $e')),
      );
    }
  }
}
