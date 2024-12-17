import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:symphonix/Providers/authProvider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    // Fetch the user details (you can get the uid from FirebaseAuth)
    String uid = FirebaseAuth.instance.currentUser!.uid;
    Provider.of<userAuthProvider>(context, listen: false).fetchUserDetails(uid);
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: screenWidth * 0.3,
              height: screenWidth * 0.3,
              decoration: BoxDecoration(
                  color: Colors.grey, borderRadius: BorderRadius.circular(100)),
            ),
            SizedBox(
              height: screenHeight * 0.03,
            ),
            Text('Name: ${authProvider.username}'),
            SizedBox(
              height: screenHeight * 0.01,
            ),
            Text('Email: ${authProvider.email}')
          ],
        ),
      ),
    );
  }
}
