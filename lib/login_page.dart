import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:iotbasedparking/register_page.dart';
import 'homepage.dart';
import 'package:email_validator/email_validator.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isLoading = false;
  String _errorMessage = '';
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  // Google login function
  Future<void> _googleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    await _googleSignIn.signOut();  // Force account picker
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      setState(() { _isLoading = false; });
      return; // User canceled
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    try {
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        // Debugging: Log user details
        print("User email: ${user.email}");
        print("User name: ${user.displayName}");

        final userRef = FirebaseDatabase.instance.ref('users/${user.uid}');

        // Check if the user exists in the database
        final userSnapshot = await userRef.get();
        if (!userSnapshot.exists) {
          // Save the user's data (including email) if not already saved
          await userRef.set({
            'name': user.displayName ?? '',  // Save user's name
            'email': user.email ?? '',        // Save user's email (if available)
            'phone': '',                      // You can also include phone if available
          });
        }

        // After saving user data, navigate to the home screen
        _navigateToHome();
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'Google login failed';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Existing login function (email/password login)
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = "Please fill in both fields.");
    } else if (!EmailValidator.validate(email)) {
      setState(() => _errorMessage = "Please enter a valid email.");
    } else {
      try {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
        final user = _auth.currentUser;
        if (user != null) {
          final userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
          final userSnapshot = await userRef.get();

          // If user data doesn't exist, create their profile with the email
          if (!userSnapshot.exists) {
            await userRef.set({
              'name': user.displayName ?? '',
              'email': user.email ?? '',
              'phone': '',  // Add phone if you have it
            });
          }
        }
        _navigateToHome();
      } on FirebaseAuthException catch (e) {
        setState(() => _errorMessage = e.message ?? 'Login failed');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const Homepage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final tween = Tween(begin: Offset(0.0, 1.0), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOut));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _opacityAnimation,
        child: Container(
          decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/back.png'), fit: BoxFit.cover)),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Login", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  _buildTextField(_emailController, "Email", false, _errorMessage.contains("email")),
                  const SizedBox(height: 15),
                  _buildTextField(_passwordController, "Password", true, !_errorMessage.contains("email")),
                  const SizedBox(height: 30),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _isLoading ? const CircularProgressIndicator(key: ValueKey('loading')) : _buildLoginButton(),
                  ),
                  const SizedBox(height: 10),
                  _buildRegisterRedirect(),
                  const SizedBox(height: 20),
                  _buildGoogleLoginButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextField _buildTextField(TextEditingController controller, String label, bool obscure, bool showError) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0)),
        errorText: showError ? _errorMessage : null,
        filled: true,
        fillColor: Colors.black.withOpacity(0.1),
      ),
    );
  }

  ElevatedButton _buildLoginButton() {
    return ElevatedButton(
      onPressed: _login,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 160, vertical: 16),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: const Text("Login"),
    );
  }

  Widget _buildRegisterRedirect() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Container(
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(30)),
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        child: TextButton(
          onPressed: _isLoading ? null : () {
            Navigator.push(context, PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const RegisterPage(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                final tween = Tween(begin: Offset(1.0, 0.0), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOut));
                return SlideTransition(position: animation.drive(tween), child: child);
              },
            ));
          },
          child: const Text("Don't have an account? Register Now", style: TextStyle(color: Colors.white, fontSize: 14)),
        ),
      ),
    );
  }

  Widget _buildGoogleLoginButton() {
    return ElevatedButton.icon(
      onPressed: _googleLogin,
      icon: const Icon(Icons.account_circle, color: Colors.white),
      label: const Text("Login with Google", style: TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}

