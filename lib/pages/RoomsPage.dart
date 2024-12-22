import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:symphonix/pages/RoomChatPage.dart';

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
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: fetchUserRooms(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('You are not part of any rooms.'),
            );
          }

          final rooms = snapshot.data!;

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ListTile(
                    title: Text('Room ID: ${room['roomId']}'),
                    subtitle: Text('Leader: ${room['leaderUsername']}'),
                    trailing: IconButton(
                        onPressed: () {
                          leaveRoom(room['roomId']);
                        },
                        icon: const Icon(Icons.exit_to_app_outlined)),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RoomChatPage(
                              roomId: room['roomId'],
                              roomName: room['leaderUsername']),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
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
                  onPressed: () async {
                    String roomId = await _createRoom(context);
                    showRoomIdBottomSheet(context, roomId);
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
                    final roomId = roomIdController.text.trim();
                    if (roomId.isNotEmpty) {
                      _joinRoom(context, roomId); // Call the join room function
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Room ID cannot be empty!')),
                      );
                    }
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

  Future<String> _createRoom(BuildContext context) async {
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
      return newRoomDoc.id;
      // Close the modal
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create room: $e')),
      );
      return '';
    }
  }

  void _joinRoom(BuildContext context, String roomId) async {
    final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
    final roomsCollection = FirebaseFirestore.instance.collection('song_rooms');

    try {
      // Check if the room exists
      DocumentSnapshot roomDoc = await roomsCollection.doc(roomId).get();

      if (!roomDoc.exists) {
        // Room does not exist
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Room with ID $roomId does not exist.')),
        );

        return;
      }

      // Fetch current members
      List<dynamic> members = roomDoc.get('members');

      if (members.contains(currentUserUid)) {
        Navigator.pop(context);
        // User is already in the room
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You are already a member of this room.')),
        );

        return;
      }

      // Add the user to the members array
      await roomsCollection.doc(roomId).update({
        'members': FieldValue.arrayUnion([currentUserUid]),
      });
      Navigator.pop(context);

      // Show a success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Joined room $roomId successfully!')),
      );

      // Close the modal
    } catch (e) {
      // Handle errors
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to join room: $e')),
      );
    }
  }

  Stream<List<Map<String, dynamic>>> fetchUserRooms() {
    final currentUserUid = FirebaseAuth.instance.currentUser!.uid;
    final roomsCollection = FirebaseFirestore.instance.collection('song_rooms');
    final usersCollection = FirebaseFirestore.instance.collection('users');

    return roomsCollection
        .where('members',
            arrayContains: currentUserUid) // Filter by user's membership
        .snapshots()
        .asyncMap((querySnapshot) async {
      List<Map<String, dynamic>> rooms = [];

      for (var doc in querySnapshot.docs) {
        var roomData = doc.data();

        // Fetch leader's username
        DocumentSnapshot leaderDoc =
            await usersCollection.doc(roomData['leader']).get();
        String leaderUsername =
            leaderDoc.exists ? leaderDoc['username'] : 'Unknown';

        rooms.add({
          'roomId': doc.id,
          'leaderUsername': leaderUsername,
        });
      }

      return rooms;
    });
  }

  void showRoomIdBottomSheet(BuildContext context, String roomId) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Room Created Successfully!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Room ID:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              SelectableText(
                roomId,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: roomId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Room ID copied to clipboard!'),
                    ),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy Room ID'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> leaveRoom(String roomId) async {
    try {
      String currentUserUid = FirebaseAuth.instance.currentUser!.uid;

      // Get the room document
      DocumentSnapshot roomSnapshot = await FirebaseFirestore.instance
          .collection('song_rooms')
          .doc(roomId)
          .get();

      if (!roomSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Room not found!')),
        );
        return;
      }

      Map<String, dynamic> roomData =
          roomSnapshot.data() as Map<String, dynamic>;
      List members = roomData['members'];
      String leader = roomData['leader'];

      if (currentUserUid == leader) {
        // If the current user is the leader, confirm dismantling the room
        bool confirm = await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Dismantle Room'),
              content: const Text(
                  'You are the leader of this room. Leaving will dismantle the entire room. Are you sure?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );

        if (confirm) {
          // Dismantle the room
          await FirebaseFirestore.instance
              .collection('song_rooms')
              .doc(roomId)
              .delete();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Room dismantled successfully!')),
          );
        }
      } else {
        // If the current user is a member, remove them from the members array
        await FirebaseFirestore.instance
            .collection('song_rooms')
            .doc(roomId)
            .update({
          'members': FieldValue.arrayRemove([currentUserUid]),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have left the room.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error leaving room: $e')),
      );
    }
  }
}
