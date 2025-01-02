import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:symphonix/Providers/authProvider.dart';
import 'package:symphonix/pages/Auth/Register.dart';
import 'package:symphonix/pages/HomePage.dart';

class LoginPage extends StatefulWidget {
  LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String errorMessage = '';

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Login')),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: screenHeight * 0.07,
              width: screenWidth * 0.85,
              child: TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Email',
                ),
              ),
            ),
            SizedBox(
              height: screenHeight * 0.02,
            ),
            SizedBox(
              height: screenHeight * 0.07,
              width: screenWidth * 0.85,
              child: TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Password',
                ),
              ),
            ),
            SizedBox(
              height: screenHeight * 0.03,
            ),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'New User? ',
                  ),
                  TextSpan(
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => RegisterPage(),
                              ));
                        },
                      text: 'Goto Register',
                      style: const TextStyle(color: Colors.blue))
                ],
              ),
            ),
            SizedBox(
              height: screenHeight * 0.03,
            ),
            ElevatedButton(
                onPressed: () async {
                  // Get user input values
                  String email = _emailController.text;
                  String password = _passwordController.text;

                  // Call the login function in the AuthProvider
                  String? result = await Provider.of<userAuthProvider>(context,
                          listen: false)
                      .loginUser(
                    email: email,
                    password: password,
                  );

                  if (result == null) {
                    // Navigate to profile page if login is successful
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => HomePage(),
                        ));
                  } else {
                    setState(() {
                      errorMessage = result; // Show error if login fails
                    });
                  }
                },
                child: const Text('SignUp'))
          ],
        ),
      ),
    );
  }
}
