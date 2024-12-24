import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class SpotifyAuthService {
  final storage = FlutterSecureStorage();

  // Your Spotify Client ID and Redirect URI
  final String clientId = '7c57679c678243258c89d3e2c7317223';
  final String redirectUri = 'symphonix://callback';

  // Function to start the authentication process
  Future<void> authenticate() async {
    try {
      // 1. Create the authentication URL
      final url = Uri.https('accounts.spotify.com', '/authorize', {
        'response_type': 'code',
        'client_id': clientId,
        'redirect_uri': redirectUri,
        'scope':
            'user-library-read playlist-read-private', // Add scopes as needed
        'show_dialog': 'true',
      });
      print('Authentication URL: ${url.toString()}'); // Debug print

      // 2. Launch the web auth
      final result = await FlutterWebAuth.authenticate(
        url: url.toString(),
        callbackUrlScheme:
            'symphonix', // Ensure this matches your redirect URI scheme
        preferEphemeral: true,
      );
      print('Auth Result: $result'); // Debug pri

      // 3. Extract the code from the result
      final Uri callbackUri = Uri.parse(result);
      final code = callbackUri.queryParameters['code'];
      print('Extracted code: $code'); // Debug print

      if (code != null) {
        // 4. Exchange the code for an access token
        String? token = await exchangeCodeForToken(code);
        print('Received token: ${token}'); // Debug print
        if (token != null) {
          await storage.write(
              key: 'spotify_token', value: token); // Store token securely
          print('authentication success...');
        }
      } else {
        print("Authentication failed. Code not found.");
        print("No code found in callback");
      }
    } catch (e, stackTrace) {
      if (e is PlatformException && e.code == "CANCELED") {
        print("Authentication was canceled. Please try again.");
        print("Detailed error: ${e.message}");
      } else {
        print("Error during authentication: $e");
      }
    }
  }

  // Function to exchange the authorization code for an access token
  Future<String?> exchangeCodeForToken(String code) async {
    const String clientSecret = '821bb2246c9e4e49a835ac77414c2d22';
    final tokenUrl = Uri.parse('https://accounts.spotify.com/api/token');
    final response = await http.post(
      tokenUrl,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization':
            'Basic ' + base64Encode(utf8.encode('$clientId:$clientSecret')),
      },
      body: {
        'code': code,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      return responseData['access_token']; // Return the token
    } else {
      print('Failed to exchange code for token: ${response.body}');
      return null;
    }
  }

  Future<void> logout() async {
    // Initialize FlutterSecureStorage
    const storage = FlutterSecureStorage();

    // Clear the stored Spotify token
    await storage.delete(key: 'spotify_token');

    // Optionally, reset any other session data or variables as needed
    print('User logged out successfully');

    // You can also show a snackbar or navigate to the login page
    // Example:
    // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Logged out successfully!')));
  }

  Future<void> fetchUserProfile() async {
    try {
      // Retrieve the stored access token
      final token = await storage.read(key: 'spotify_token');

      if (token == null) {
        print('No token found. User is not authenticated.');
        return;
      }

      // Make a GET request to Spotify's /me endpoint
      final response = await http.get(
        Uri.parse('https://api.spotify.com/v1/me'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        // Parse and display the user's profile data
        final Map<String, dynamic> userData = json.decode(response.body);
        print('User Profile Data: $userData');
        print('Display Name: ${userData['display_name']}');
        print('Email: ${userData['email']}');
        print('Profile Image: ${userData['images']?.first['url']}');
      } else {
        print('Failed to fetch user profile: ${response.body}');
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }
}
