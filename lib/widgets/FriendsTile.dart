import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:symphonix/Providers/searchProvider.dart';

class FriendTile extends StatelessWidget {
  final String username;
  final String uid;

  const FriendTile({
    Key? key,
    required this.username,
    required this.uid,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(), borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListTile(
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(100), color: Colors.grey),
            ),
            title: Text(
              username,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Text('Loading...');
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return Text('Offline');
                }

                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final currentlyPlaying = data?['currentlyPlaying'];

                if (currentlyPlaying == null) {
                  const Text('Offline');
                } else {
                  return Text(
                      'Listening to: ${currentlyPlaying['songName']} by ${currentlyPlaying['artistName']}');
                }
                return const Text('Offline');
              },
            ),
            trailing: IconButton(
                onPressed: () async {
                  await Provider.of<SearchProvider>(context, listen: false)
                      .unfriendUser(uid);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('User unfriended successfully')),
                  );
                },
                icon: const Icon(Icons.delete)),
          ),
        ),
      ),
    );
  }
}
