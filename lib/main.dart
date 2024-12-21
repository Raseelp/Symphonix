import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:symphonix/Providers/authProvider.dart';
import 'package:symphonix/Providers/searchProvider.dart';
import 'package:symphonix/firebase_options.dart';
import 'package:symphonix/pages/Auth/Login.dart';
import 'package:symphonix/pages/Auth/Register.dart';
import 'package:symphonix/pages/FriendsFeed.dart';
import 'package:symphonix/pages/HomePage.dart';
import 'package:symphonix/pages/ProfilePage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(
      create: (context) => userAuthProvider(),
    ),
    ChangeNotifierProvider(
      create: (context) => SearchProvider(),
    )
  ], child: const Symphonix()));
}

class Symphonix extends StatelessWidget {
  const Symphonix({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AuthWrapper(),
    );
  }
}

// AuthWrapper: Check if the user is logged in or not
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is logged in, fetch their details and navigate to ProfilePage
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Provider.of<userAuthProvider>(context, listen: false)
            .fetchUserDetails(user.uid);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomePage(),
          ),
        );
      });
      return const SizedBox(); // Empty widget during redirection
    } else {
      // User is not logged in, show LoginPage
      return LoginPage();
    }
  }
}
