import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class UserStatsPage extends StatefulWidget {
  const UserStatsPage({super.key});

  @override
  State<UserStatsPage> createState() => _UserStatsPageState();
}

class _UserStatsPageState extends State<UserStatsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stats'),
      ),
    );
  }
}
