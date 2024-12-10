import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iotbasedparking/login_page.dart'; // Import Login Page
import 'package:email_validator/email_validator.dart';  // Email validator package

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  String _errorMessage = '';

  void _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';  // Reset error message
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validate email and password
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Please fill in both fields.";
      });
      return;
    }

    if (!EmailValidator.validate(email)) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Please enter a valid email address.";
      });
      return;
    }

    try {
      // Register the user with email and password
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful! Please log in.')),
      );

      // Navigate back to Login Page after successful registration
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } on FirebaseAuthException catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Registration failed')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/back.png'), // Same background image as LoginPage
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Register",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,  // Text color matching LoginPage
                  ),
                ),
                const SizedBox(height: 20),
                // Email Input Field
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email",
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.1),
                  ),
                ),
                const SizedBox(height: 15),
                // Password Input Field
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: TextStyle(color: Colors.black),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.1),
                  ),
                ),
                const SizedBox(height: 30),
                // Loading or Register Button
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _register,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 155, vertical: 15),
                    backgroundColor: Colors.red,  // Match the LoginPage button color
                    foregroundColor: Colors.white,  // Set text color (white)
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Rounded corners
                    ),
                  ),
                  child: const Text("Register"),
                ),
                const SizedBox(height: 20),
                // Link to go back to Login page with adjustable padding
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),  // Horizontal padding for the button container
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),  // Black background for the button
                      borderRadius: BorderRadius.circular(30),  // Rounded corners for consistency
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 5),  // Adjustable padding for inside the button
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);  // Go back to Login page
                      },
                      child: const Text(
                        "Already have an account? Log In",
                        style: TextStyle(
                          color: Colors.white,  // White text color for visibility
                          fontSize: 14,  // Text size can be adjusted
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
