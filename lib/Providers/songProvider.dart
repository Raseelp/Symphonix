// lib/providers/song_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SongProvider with ChangeNotifier {
  String _songName = '';
  String _artistName = '';
  String _albumArtUrl = '';
  String _playbackStatus = '';
  int _playbackTimestamp = 0;
  String _songURI = '';

  String get songName => _songName;
  String get artistName => _artistName;
  String get albumArtUrl => _albumArtUrl;
  String get playbackStatus => _playbackStatus;
  String get songURI => _songURI;
  int get playbackTimestamp => _playbackTimestamp;

  void updateSongDetails(Map<String, dynamic> data) {
    _songName = data['songName'] ?? '';
    _artistName = data['artistName'] ?? '';
    _albumArtUrl = data['albumArtUrl'] ?? '';
    _playbackStatus = data['playbackStatus'] ?? '';
    _playbackTimestamp = data['playbackTimestamp'] ?? 0;
    _songURI = data['songURI'];
    notifyListeners();
  }
}
