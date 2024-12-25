import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:symphonix/services/spotify_services.dart';
import 'package:http/http.dart' as http;

class UserStatsPage extends StatefulWidget {
  const UserStatsPage({super.key});

  @override
  State<UserStatsPage> createState() => _UserStatsPageState();
}

class _UserStatsPageState extends State<UserStatsPage> {
  final storage = FlutterSecureStorage();
  String? songName;
  String? artistName;
  String? albumArtUrl;
  bool isLoading = true;
  final SpotifyAuthService authService = SpotifyAuthService();

  @override
  void initState() {
    super.initState();
    fetchCurrentlyPlayingSong();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('User Stats')),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : songName != null
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            border: Border.all(),
                            borderRadius: BorderRadius.circular(20)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Listening Now',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              Row(
                                children: [
                                  if (albumArtUrl != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Image.network(
                                        albumArtUrl!,
                                        height: 70,
                                        width: 70,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  SizedBox(
                                    width: screenWidth * 0.05,
                                  ),
                                  Column(
                                    children: [
                                      Text(
                                        songName ?? 'Unknown Song',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        artistName ?? 'Unknown Artist',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const Center(
                  child: Text(
                    'No song is currently playing.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
    );
  }

  Future<void> fetchCurrentlyPlayingSong() async {
    try {
      // Retrieve the stored access token
      final token = await storage.read(key: 'spotify_token');
      if (token == null) {
        setState(() {
          isLoading = false;
        });
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
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
          print('No song is currently playing.');
        }
      } else {
        setState(() {
          isLoading = false;
        });
        print('Failed to fetch currently playing song: ${response.body}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching currently playing song: $e');
    }
  }
}
