import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:symphonix/Providers/authProvider.dart';
import 'package:symphonix/Providers/searchProvider.dart';
import 'package:symphonix/pages/Auth/Login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String searchText = "";
  List<Map<String, dynamic>> searchResults = [];

  void performSearch() async {
    if (searchText.isNotEmpty) {
      var results = await Provider.of<SearchProvider>(context, listen: false)
          .searchUsers(searchText);
      setState(() {
        searchResults = results;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Fetch the user details (you can get the uid from FirebaseAuth)
    String uid = FirebaseAuth.instance.currentUser!.uid;
    Provider.of<userAuthProvider>(context, listen: false).fetchUserDetails(uid);
    Provider.of<SearchProvider>(context, listen: false).fetchFriendRequests();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    final authProvider = Provider.of<userAuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Profile')),
      ),
      body: SingleChildScrollView(
        child: SizedBox(
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Container(
                width: screenWidth * 0.3,
                height: screenWidth * 0.3,
                decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(100)),
              ),
              SizedBox(
                height: screenHeight * 0.03,
              ),
              Text('Name: ${authProvider.username}'),
              SizedBox(
                height: screenHeight * 0.01,
              ),
              Text('Email: ${authProvider.email}'),
              SizedBox(
                height: screenHeight * 0.03,
              ),
              ElevatedButton(
                onPressed: () async {
                  await Provider.of<userAuthProvider>(context, listen: false)
                      .logoutUser();
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoginPage(),
                      ));
                },
                child: const Text('LogOut'),
              ),
              SizedBox(
                height: screenHeight * 0.03,
              ),
              Container(
                height: screenHeight * 0.2,
                child: Consumer<SearchProvider>(
                    builder: (context, searchProvider, child) {
                  return ListView.builder(
                    shrinkWrap:
                        true, // Ensures the ListView only takes as much height as its content
                    physics:
                        BouncingScrollPhysics(), // Enables scrolling within the container
                    itemCount: Provider.of<SearchProvider>(context)
                        .friendRequests
                        .length, // Assuming this is the list of friend requests
                    itemBuilder: (context, index) {
                      var request = Provider.of<SearchProvider>(context)
                          .friendRequests[index];
                      return ListTile(
                        title: Text(request['username']),
                        subtitle: Text(request['email']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon:
                                  const Icon(Icons.check, color: Colors.green),
                              onPressed: () async {
                                await Provider.of<SearchProvider>(context,
                                        listen: false)
                                    .acceptFriendRequest(request['uid']);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Friend request from ${request['username']} accepted!'),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () async {
                                await Provider.of<SearchProvider>(context,
                                        listen: false)
                                    .declineFriendRequest(request['uid']);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Friend request from ${request['username']} declined!'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),
              SizedBox(
                height: screenHeight * 0.01,
              ),
              SizedBox(
                height: screenHeight * 0.07,
                width: screenWidth * 0.85,
                child: TextField(
                  onChanged: (value) {
                    searchText = value;
                    performSearch();
                    print(searchResults);
                  },
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Search Friends',
                  ),
                ),
              ),
              SizedBox(
                height: screenHeight * 0.3,
                child: ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    var user = searchResults[index];
                    return ListTile(
                      title: Text(user['username']),
                      subtitle: Text(user['email']),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          String receiverUid = user['uid'];
                          await Provider.of<SearchProvider>(context,
                                  listen: false)
                              .sendFriendRequest(receiverUid);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Friend request sent to ${user['username']}')),
                          );
                        },
                        child: const Text("Send Request"),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
