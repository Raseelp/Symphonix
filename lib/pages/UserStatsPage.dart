import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:symphonix/services/spotify_services.dart';
import 'package:http/http.dart' as http;

class UserStatsPage extends StatefulWidget {
  const UserStatsPage({super.key});

  @override
  State<UserStatsPage> createState() => _UserStatsPageState();
}

class _UserStatsPageState extends State<UserStatsPage> {
  final storage = const FlutterSecureStorage();
  String? songName;
  String? artistName;
  String? albumArtUrl;
  List<Map<String, dynamic>> topSongs = [];
  List<Map<String, dynamic>> topArtists = [];
  List<Map<String, dynamic>> recentlyPlayed = [];
  bool isLoading = true;
  String selectedDuration = 'short_term';
  final SpotifyAuthService authService = SpotifyAuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance; // Firebase Auth instance

  @override
  void initState() {
    String currentUid = _auth.currentUser!.uid;
    super.initState();
    // fetchCurrentlyPlayingSong(currentUid);

    fetchTopSongs();
    fetchTopArtists();
    fetchRecentlyPlayedSongs();
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
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Listening Now Section
                    _buildListeningNowContainer(
                      screenWidth,
                    ),
                    const SizedBox(height: 20),
                    // Top Songs Section
                    _buildTopSongsSection(),
                    const SizedBox(height: 20),
                    _buildTopArtistsSection(),
                    const SizedBox(height: 20),
                    _buildRecentlyPlayedSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildListeningNowContainer(double screenWidth) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: songName != null
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Listening Now',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
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
                      SizedBox(width: screenWidth * 0.05),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            songName ?? 'Unknown Song',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            artistName ?? 'Unknown Artist',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              )
            : const Center(
                child: Text(
                  'No song is currently playing.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
      ),
    );
  }

  Widget _buildTopSongsSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Duration Buttons
            const Text(
              'Top 5 Songs',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),
            // Top Songs List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDurationButton('Last 30 Days', 'short_term', true),
                _buildDurationButton('Last 6 Months', 'medium_term', true),
                _buildDurationButton('All Time', 'long_term', true),
              ],
            ),
            const SizedBox(height: 5),
            ...topSongs.map((song) => ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      song['albumArtUrl']!,
                      height: 50,
                      width: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    song['songName']!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(song['artistName']!),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTopArtistsSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Duration Buttons
            const Text(
              'Top 5 Artists',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),
            // Top Songs List
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDurationButton('Last 30 Days', 'short_term', false),
                _buildDurationButton('Last 6 Months', 'medium_term', false),
                _buildDurationButton('All Time', 'long_term', false),
              ],
            ),
            const SizedBox(height: 5),
            ...topArtists.map((artist) => ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      artist['artistImageUrl']!,
                      height: 50,
                      width: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    artist['artistName']!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(artist['genres']!),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentlyPlayedSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Duration Buttons
            const Text(
              'Recently Played',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 10),
            // Top Songs List

            const SizedBox(height: 5),
            ...recentlyPlayed.map((song) => ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      song['albumArtUrl']!,
                      height: 50,
                      width: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    song['songName']!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(song['artistName']!),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationButton(String label, String duration, bool songsOrNot) {
    bool isSong = songsOrNot;
    return SizedBox(
      width: 100,
      height: 40,
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            selectedDuration = duration;
            isLoading = true;
          });
          isSong ? fetchTopSongs() : fetchTopArtists();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              selectedDuration == duration ? Colors.blue : Colors.white,
        ),
        child: Text(
          textAlign: TextAlign.center,
          label,
          style: const TextStyle(color: Colors.black),
        ),
      ),
    );
  }

  // Future<void> fetchCurrentlyPlayingSong(String currentUid) async {
  //   try {
  //     // Retrieve the stored access token
  //     final token = await storage.read(key: 'spotify_token');
  //     if (token == null) {
  //       setState(() {
  //         isLoading = false;
  //       });
  //       print('No token found. User is not authenticated.');
  //       return;
  //     }

  //     // Make a GET request to Spotify's /me/player/currently-playing endpoint
  //     final response = await http.get(
  //       Uri.parse('https://api.spotify.com/v1/me/player/currently-playing'),
  //       headers: {'Authorization': 'Bearer $token'},
  //     );

  //     if (response.statusCode == 200) {
  //       final currentlyPlayingData =
  //           json.decode(response.body) as Map<String, dynamic>;
  //       if (currentlyPlayingData.isNotEmpty &&
  //           currentlyPlayingData['item'] != null) {
  //         final track = currentlyPlayingData['item'];
  //         setState(() {
  //           songName = track['name'];
  //           artistName =
  //               (track['artists'] as List).map((a) => a['name']).join(', ');
  //           albumArtUrl = track['album']['images'][0]['url'];
  //           isLoading = false;
  //         });

  //         // Get the current user's UID (replace with the actual method you use to get the UID)
  //         // Replace this with actual user ID retrieval method

  //         // Save the currently playing song to Firestore
  //         FirebaseFirestore.instance
  //             .collection('users')
  //             .doc(currentUid)
  //             .update({
  //           'currentlyPlaying': {
  //             'songName': songName,
  //             'artistName': artistName,
  //             'albumArtUrl': albumArtUrl,
  //           },
  //         }).then((_) {
  //           print('Currently playing song updated in Firestore');
  //         }).catchError((error) {
  //           print('Error updating song: $error');
  //         });
  //       } else {
  //         setState(() {
  //           isLoading = false;
  //         });
  //         // Set currentlyPlaying to null if no song is playing.
  //         await FirebaseFirestore.instance
  //             .collection('users')
  //             .doc(currentUid)
  //             .update({
  //           'currentlyPlaying': null,
  //         });

  //         print('No song is currently playing.');
  //       }
  //     } else {
  //       setState(() {
  //         isLoading = false;
  //       });
  //       await FirebaseFirestore.instance
  //           .collection('users')
  //           .doc(currentUid)
  //           .update({
  //         'currentlyPlaying': null,
  //       });

  //       print('Failed to fetch currently playing song: ${response.body}');
  //     }
  //   } catch (e) {
  //     setState(() {
  //       isLoading = false;
  //     });
  //     await FirebaseFirestore.instance
  //         .collection('users')
  //         .doc(currentUid)
  //         .update({
  //       'currentlyPlaying': null,
  //     });
  //     print('Error fetching currently playing song: $e');
  //   }
  // }

  Future<void> fetchTopSongs() async {
    try {
      final token = await storage.read(key: 'spotify_token');
      if (token == null) {
        setState(() {
          isLoading = false;
        });
        print('No token found. User is not authenticated.');
        return;
      }

      final response = await http.get(
        Uri.parse(
          'https://api.spotify.com/v1/me/top/tracks?time_range=$selectedDuration&limit=5',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final topTracksData =
            json.decode(response.body) as Map<String, dynamic>;
        final items = topTracksData['items'] as List<dynamic>;
        setState(() {
          topSongs = items.map((track) {
            return {
              'songName': track['name'],
              'artistName': (track['artists'] as List)
                  .map((artist) => artist['name'])
                  .join(', '),
              'albumArtUrl': track['album']['images'][0]['url'],
            };
          }).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print('Failed to fetch top songs: ${response.body}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching top songs: $e');
    }
  }

  Future<void> fetchTopArtists() async {
    try {
      final token = await storage.read(key: 'spotify_token');
      if (token == null) {
        setState(() {
          isLoading = false;
        });
        print('No token found. User is not authenticated.');
        return;
      }

      // Make a GET request to Spotify's /me/top/artists endpoint
      final response = await http.get(
        Uri.parse(
          'https://api.spotify.com/v1/me/top/artists?time_range=$selectedDuration&limit=5',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final topArtistsData =
            json.decode(response.body) as Map<String, dynamic>;
        final items = topArtistsData['items'] as List<dynamic>;
        setState(() {
          topArtists = items.map((artist) {
            return {
              'artistName': artist['name'],
              'artistImageUrl': artist['images'][0]['url'],
              'genres': (artist['genres'] as List).join(', '),
            };
          }).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print('Failed to fetch top artists: ${response.body}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching top artists: $e');
    }
  }

  Future<void> fetchRecentlyPlayedSongs() async {
    try {
      final token = await storage.read(key: 'spotify_token');
      if (token == null) {
        setState(() {
          isLoading = false;
        });
        print('No token found. User is not authenticated.');
        return;
      }

      // Make a GET request to Spotify's /me/player/recently-played endpoint
      final response = await http.get(
        Uri.parse(
          'https://api.spotify.com/v1/me/player/recently-played?limit=5',
        ),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final recentlyPlayedData =
            json.decode(response.body) as Map<String, dynamic>;
        final items = recentlyPlayedData['items'] as List<dynamic>;
        setState(() {
          recentlyPlayed = items.map((track) {
            return {
              'songName': track['track']['name'],
              'artistName': (track['track']['artists'] as List)
                  .map((artist) => artist['name'])
                  .join(', '),
              'albumArtUrl': track['track']['album']['images'][0]['url'],
            };
          }).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print('Failed to fetch recently played songs: ${response.body}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching recently played songs: $e');
    }
  }
}
