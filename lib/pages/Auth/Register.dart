import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:symphonix/Providers/authProvider.dart';
import 'package:symphonix/pages/Auth/Login.dart';
import 'package:symphonix/pages/HomePage.dart';

class RegisterPage extends StatelessWidget {
  final _emailController = TextEditingController();
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();

  RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('SignUp')),
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
              height: screenHeight * 0.02,
            ),
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'Already have an account? ',
                  ),
                  TextSpan(
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => LoginPage(),
                            ));
                      },
                    text: 'Goto Login',
                    style: const TextStyle(color: Colors.blue),
                  )
                ],
              ),
            ),
            SizedBox(
              height: screenHeight * 0.02,
            ),
            ElevatedButton(
              onPressed: () async {
                final authProvider =
                    Provider.of<userAuthProvider>(context, listen: false);

                String? error = await authProvider.registerUser(
                  email: _emailController.text.trim(),
                  password: _passwordController.text.trim(),
                  username: _userNameController.text.trim(),
                );

                if (error == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Registration Successful!")),
                  );
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => HomePage(),
                      ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $error")),
                  );
                }
              },
              child: const Text('SignUp'),
            )
          ],
        ),
      ),
    );
  }
}
