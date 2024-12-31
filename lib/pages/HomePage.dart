import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:symphonix/pages/FriendsFeed.dart';
import 'package:symphonix/pages/ProfilePage.dart';
import 'package:symphonix/pages/RoomsPage.dart';
import 'package:symphonix/pages/UserStatsPage.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final storage = const FlutterSecureStorage();
  String? songName;
  String? artistName;
  String? albumArtUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance
  @override
  void initState() {
    Timer.periodic(const Duration(seconds: 10), (timer) {
      String currentUid = _auth.currentUser!.uid;
      fetchCurrentlyPlayingSong(currentUid);
    });
  }

  // List of pages for each slot
  final List<Widget> _pages = [
    FriednsFeed(),
    RoomPage(),
    UserStatsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Ensures 4 items are displayed
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Update selected index
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.create_new_folder),
            label: 'Rooms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.query_stats),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Future<void> fetchCurrentlyPlayingSong(String currentUid) async {
    try {
      // Retrieve the stored acce ss token
      final token = await storage.read(key: 'spotify_token');
      if (token == null) {
        print('No token found. User is not authenticated.');
        return;
      }

      // Make a GET request to Spotify's /me/player/currently-playing endpoint
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/me/player/currently-playing'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final currentlyPlayingData =
            json.decode(response.body) as Map<String, dynamic>;
        if (currentlyPlayingData.isNotEmpty &&
            currentlyPlayingData['item'] != null) {
          final track = currentlyPlayingData['item'];
          setState(() {
            songName = track['name'];
            artistName =
                (track['artists'] as List).map((a) => a['name']).join(', ');
            albumArtUrl = track['album']['images'][0]['url'];
          });

          // Get the current user's UID (replace with the actual method you use to get the UID)
          // Replace this with actual user ID retrieval method

          // Save the currently playing song to Firestore
          FirebaseFirestore.instance
              .collection('users')
              .doc(currentUid)
              .update({
            'currentlyPlaying': {
              'songName': songName,
              'artistName': artistName,
              'albumArtUrl': albumArtUrl,
            },
          }).then((_) {
            print('Currently playing song updated in Firestore');
          }).catchError((error) {
            print('Error updating song: $error');
          });
        } else {
          // Set currentlyPlaying to null if no song is playing.
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUid)
              .update({
            'currentlyPlaying': null,
          });

          print('No song is currently playing.');
        }
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUid)
            .update({
          'currentlyPlaying': null,
        });

        print('Failed to fetch currently playing song: ${response.body}');
      }
    } catch (e) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUid)
          .update({
        'currentlyPlaying': null,
      });
      print('Error fetching currently playing song: $e');
    }
  }
}
