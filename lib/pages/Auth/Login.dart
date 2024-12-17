import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:symphonix/pages/Auth/Register.dart';

class LoginPage extends StatelessWidget {
  LoginPage({super.key});
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();

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
                controller: _userNameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'UserName',
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
            ElevatedButton(onPressed: () {}, child: const Text('SignUp'))
          ],
        ),
      ),
    );
  }
}
