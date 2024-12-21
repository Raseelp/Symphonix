import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:symphonix/pages/FriendsChatScreen.dart';
import 'package:symphonix/widgets/FriendsTile.dart';

class FriednsFeed extends StatelessWidget {
  const FriednsFeed({super.key});
  Stream<List<Map<String, dynamic>>> fetchFriends() {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    String currentUid = auth.currentUser!.uid;

    return firestore
        .collection('users')
        .doc(currentUid)
        .snapshots()
        .asyncMap((userDoc) async {
      List<dynamic> friendUids = userDoc.data()?['friends'] ?? [];
      List<Map<String, dynamic>> friendsList = [];

      for (String friendUid in friendUids) {
        DocumentSnapshot friendDoc =
            await firestore.collection('users').doc(friendUid).get();
        if (friendDoc.exists) {
          friendsList.add({
            'username': friendDoc['username'],
            'uid': friendDoc['uid'],
          });
        }
      }
      return friendsList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Friends')),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: fetchFriends(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No friends yet.'));
          }

          final friends = snapshot.data!;
          print(friends);
          return ListView.builder(
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friend = friends[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FriendChatPage(
                          reciverUserID: friend['uid'],
                          reciverUserName: friend['username'],
                        ),
                      ));
                },
                child: FriendTile(
                  uid: friend['uid'],
                  username: friend['username'],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
