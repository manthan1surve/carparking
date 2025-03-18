import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:iotbasedparking/login_page.dart';
import 'package:email_validator/email_validator.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String _errorMessage = '';
  String _passwordErrorMessage = '';
  bool _obscureText = true; // Add this line to manage password visibility
  late AnimationController _controller;
  late Animation<double> _scaleAnimation, _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  Future<void> _register() async {
    setState(() => _isLoading = true);
    _controller.forward();

    final email = _emailController.text.trim(),
        password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty || !EmailValidator.validate(email)) {
      setState(() =>
      _errorMessage = email.isEmpty || password.isEmpty
          ? "Please fill in both fields."
          : "Invalid email.");
      setState(() => _isLoading = false);
      return;
    }

    // Password Validation
    if (password.length < 6) {
      setState(() =>
      _passwordErrorMessage = "Password must be at least 6 characters.");
    } else if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      setState(() =>
      _passwordErrorMessage =
      "Password must contain at least one special character.");
    } else {
      _passwordErrorMessage = '';
    }

    // If password has error, stop the registration process
    if (_passwordErrorMessage.isNotEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      if (await _auth.fetchSignInMethodsForEmail(email).then((
          methods) => methods.isNotEmpty)) {
        setState(() => _errorMessage = "Email is already registered.");
        setState(() => _isLoading = false);
        return;
      }

      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final user = _auth.currentUser;
      if (user != null) {
        final userRef = FirebaseDatabase.instance.ref('users/${user.uid}');
        if (!(await userRef.get()).exists) {
          await userRef.set({
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'phone': ''
          });
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Registration successful! Please log in.')));
      Navigator.pushReplacement(context, PageRouteBuilder(
          pageBuilder: (context, animation,
              secondaryAnimation) => const LoginPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            return SlideTransition(position: animation.drive(
                Tween(begin: begin, end: Offset.zero).chain(
                    CurveTween(curve: Curves.easeInOut))), child: child);
          }));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Registration failed')));
    } finally {
      setState(() => _isLoading = false);
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(image: DecorationImage(
              image: AssetImage('assets/images/back.png'), fit: BoxFit.cover)),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(opacity: _fadeAnimation,
                      child: const Text("Register", style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.black))),
                  const SizedBox(height: 20),
                  FadeTransition(opacity: _fadeAnimation,
                      child: _buildTextField(
                          _emailController, "Email", _errorMessage)),
                  const SizedBox(height: 15),
                  FadeTransition(opacity: _fadeAnimation,
                      child: _buildTextField(_passwordController, "Password",
                          _passwordErrorMessage, obscureText: _obscureText)),
                  const SizedBox(height: 30),
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets
                          .symmetric(horizontal: 155, vertical: 15),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30))),
                      child: const Text("Register"),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Container(
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 1, horizontal: 5),
                      child: TextButton(onPressed: () => Navigator.pop(context),
                          child: const Text("Already have an account? Log In",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 14))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      String? errorMessage, {bool obscureText = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(color: Colors.black),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30.0)),
            errorText: errorMessage,
            filled: true,
            fillColor: Colors.black.withOpacity(0.1),
            suffixIcon: label == 'Password'
                ? IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: Colors.black,
              ),
              onPressed: () {
                setState(() {
                  _obscureText = !_obscureText;
                });
              },
            )
                : null,
          ),
        ),
        if (label == 'Password' && _passwordErrorMessage.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _passwordErrorMessage,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }
}










