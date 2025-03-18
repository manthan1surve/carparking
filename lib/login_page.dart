import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:iotbasedparking/register_page.dart';
import 'homepage.dart';
import 'package:email_validator/email_validator.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String _errorMessage = '';
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 600), vsync: this);
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _slideAnimation = Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Please fill in both fields.";
      });
    } else if (!EmailValidator.validate(email)) {
      setState(() {
        _errorMessage = "Invalid email format.";
      });
    } else {
      try {
        await _auth.signInWithEmailAndPassword(email: email, password: password);
        final user = _auth.currentUser;
        if (user != null) {
          final userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
          final userSnapshot = await userRef.get();
          if (!userSnapshot.exists) {
            await userRef.set({'name': user.displayName ?? '', 'email': user.email ?? '', 'phone': ''});
          }
        }
        _navigateToHome();
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = e.code == 'user-not-found' ? "Invalid email address." : e.code == 'wrong-password' ? "Incorrect password." : 'Login failed. Please try again.';
        });
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToHome() {
    Navigator.pushReplacement(context, PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => const Homepage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) => SlideTransition(position: animation.drive(Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOut))), child: child),
    ));
  }

  TextField _buildTextField(TextEditingController controller, String label, bool obscure, bool showError) {
    return TextField(
      controller: controller,
      obscureText: obscure && !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0)),
        errorText: showError ? _errorMessage : null,
        filled: true,
        fillColor: Colors.black.withOpacity(0.1),
        suffixIcon: obscure
            ? IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.black,
          ),
          onPressed: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        )
            : null,
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
          onPressed: _isLoading ? null : () => Navigator.push(context, PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const RegisterPage(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) => SlideTransition(position: animation.drive(Tween(begin: Offset(1.0, 0.0), end: Offset.zero).chain(CurveTween(curve: Curves.easeInOut))), child: child),
          )),
          child: const Text("Don't have an account? Register Now", style: TextStyle(color: Colors.white, fontSize: 14)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _opacityAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            decoration: const BoxDecoration(image: DecorationImage(image: AssetImage('assets/images/back.png'), fit: BoxFit.cover)),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Login", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
                    const SizedBox(height: 20),
                    _buildTextField(_emailController, "Email", false, _errorMessage.contains("email")),
                    const SizedBox(height: 15),
                    _buildTextField(_passwordController, "Password", true, !_errorMessage.contains("email")),
                    if (_errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(_errorMessage, style: TextStyle(color: Colors.red, fontSize: 14)),
                    ],
                    const SizedBox(height: 30),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _isLoading ? const CircularProgressIndicator(key: ValueKey('loading')) : _buildLoginButton(),
                    ),
                    const SizedBox(height: 10),
                    _buildRegisterRedirect(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}





