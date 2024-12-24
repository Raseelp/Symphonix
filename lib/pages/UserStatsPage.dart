import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:symphonix/services/spotify_services.dart';

class UserStatsPage extends StatefulWidget {
  const UserStatsPage({super.key});

  @override
  State<UserStatsPage> createState() => _UserStatsPageState();
}

class _UserStatsPageState extends State<UserStatsPage> {
  final SpotifyAuthService authService = SpotifyAuthService();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Stats')),
      ),
      body: Column(
        children: [
          ElevatedButton(
              onPressed: () async {
                await authService.fetchUserProfile();
              },
              child: const Text('Fetch Spotify Profile Data'))
        ],
      ),
    );
  }
}
