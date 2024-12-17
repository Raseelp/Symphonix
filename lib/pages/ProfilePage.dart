import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

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
            Text('Name'),
            SizedBox(
              height: screenHeight * 0.01,
            ),
            Text('Email@gamil.com')
          ],
        ),
      ),
    );
  }
}
