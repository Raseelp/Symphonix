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
            title: Text(username),
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
