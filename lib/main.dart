import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:symphonix/Providers/authProvider.dart';
import 'package:symphonix/firebase_options.dart';
import 'package:symphonix/pages/Auth/Login.dart';
import 'package:symphonix/pages/Auth/Register.dart';
import 'package:symphonix/pages/ProfilePage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(
      create: (context) => userAuthProvider(),
    )
  ], child: const Symphonix()));
}

class Symphonix extends StatelessWidget {
  const Symphonix({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: RegisterPage(),
    );
  }
}
