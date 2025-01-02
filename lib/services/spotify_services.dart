import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class SpotifyAuthService {
  final storage = FlutterSecureStorage();

  //  Spotify Client ID and Redirect URI
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
            'user-library-read playlist-read-private user-read-recently-played user-read-currently-playing user-library-read playlist-read-private user-top-read', // Add scopes as needed
        'show_dialog': 'true',
      });
      print('Authentication URL: ${url.toString()}'); // Debug print

      // 2. Launch the web auth
      final result = await FlutterWebAuth.authenticate(
        url: url.toString(),
        callbackUrlScheme:
            'symphonix', // Ensure this matches  redirect URI scheme
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
      final accessToken = responseData['access_token'];
      final refreshToken = responseData['refresh_token'];
      final expiresIn = responseData['expires_in']; // Time in seconds

      // Save tokens and expiration time
      await storage.write(key: 'spotify_token', value: accessToken);
      await storage.write(key: 'spotify_refresh_token', value: refreshToken);
      await storage.write(
        key: 'spotify_token_expiration',
        value: DateTime.now()
            .add(Duration(seconds: expiresIn))
            .millisecondsSinceEpoch
            .toString(),
      );

      return accessToken;
    } else {
      print('Failed to exchange code for token: ${response.body}');
      return null;
    }
  }

  Future<String?> refreshAccessToken() async {
    const String clientSecret = '821bb2246c9e4e49a835ac77414c2d22';
    final refreshToken = await storage.read(key: 'spotify_refresh_token');
    final tokenUrl = Uri.parse('https://accounts.spotify.com/api/token');

    if (refreshToken == null) {
      print('No refresh token found. User needs to re-authenticate.');
      return null;
    }

    final response = await http.post(
      tokenUrl,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization':
            'Basic ' + base64Encode(utf8.encode('$clientId:$clientSecret')),
      },
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      final accessToken = responseData['access_token'];
      final expiresIn = responseData['expires_in']; // Time in seconds

      // Update token and expiration time
      await storage.write(key: 'spotify_token', value: accessToken);
      await storage.write(
        key: 'spotify_token_expiration',
        value: DateTime.now()
            .add(Duration(seconds: expiresIn))
            .millisecondsSinceEpoch
            .toString(),
      );

      return accessToken;
    } else {
      print('Failed to refresh token: ${response.body}');
      return null;
    }
  }

  Future<String?> getValidAccessToken() async {
    final accessToken = await storage.read(key: 'spotify_token');
    final expirationTime = await storage.read(key: 'spotify_token_expiration');

    if (expirationTime != null &&
        DateTime.now().millisecondsSinceEpoch > int.parse(expirationTime)) {
      print('Token expired. Refreshing...');
      return await refreshAccessToken();
    }

    return accessToken;
  }

  Future<void> logout() async {
    // Initialize FlutterSecureStorage
    const storage = FlutterSecureStorage();

    // Clear all stored Spotify tokens and related session data
    await storage.delete(key: 'spotify_token');
    await storage.delete(key: 'spotify_refresh_token');
    await storage.delete(key: 'spotify_token_expiration');

    print('User logged out successfully and all session data cleared.');
  }
}
