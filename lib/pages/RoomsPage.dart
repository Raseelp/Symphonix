import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RoomPage extends StatefulWidget {
  @override
  _RoomPageState createState() => _RoomPageState();
}

class _RoomPageState extends State<RoomPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'No Rooms Yet',
          style: TextStyle(fontSize: 18),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRoomOptions(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showRoomOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16.0),
          height: 200,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close the bottom sheet
                  _showCreateRoomBottomSheet(context);
                },
                child: const Text('Create Room'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close the bottom sheet
                  _showJoinRoomBottomSheet(context);
                },
                child: const Text('Join Room'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateRoomBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // To adjust for keyboard
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets, // Adjust for keyboard
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create a Room',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _createRoom(context);
                  },
                  child: const Text('Create'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showJoinRoomBottomSheet(BuildContext context) {
    TextEditingController roomIdController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // To adjust for keyboard
      builder: (context) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets, // Adjust for keyboard
          child: Container(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Join a Room',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: roomIdController,
                  decoration: const InputDecoration(
                    labelText: 'Room ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    String roomId = roomIdController.text.trim();
                    // Add join room functionality here
                  },
                  child: const Text('Join'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _createRoom(BuildContext context) async {
    final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
    final roomsCollection = FirebaseFirestore.instance.collection('song_rooms');

    try {
      // Generate a unique ID for the room
      final newRoomDoc = roomsCollection.doc();

      // Prepare the room data
      final roomData = {
        'members': [currentUserUid],
        'leader': currentUserUid,
        'createdAt': FieldValue.serverTimestamp(),
        'roomId': newRoomDoc.id,
      };

      // Create the room in Firestore
      await newRoomDoc.set(roomData);

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room created! Room ID: ${newRoomDoc.id}')),
      );

      // Close the modal
      Navigator.pop(context);
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create room: $e')),
      );
    }
  }
}
