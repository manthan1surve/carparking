import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:iotbasedparking/parkingspace1.dart';
import 'package:iotbasedparking/parkingspace2.dart';
import 'package:iotbasedparking/parkingspace3.dart';
import 'package:iotbasedparking/profile.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: const Homepage());
  }
}

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Levels', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey,
        elevation: 0,
        centerTitle: true, // Ensures the title is centered
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.black),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/back.png'),
            fit: BoxFit.cover, // Ensure the image covers the screen
            alignment: Alignment.center,
          ),
        ),
        child: SafeArea(
          child: Center( // Ensures the content is centered both vertically and horizontally
            child: Column(
              mainAxisSize: MainAxisSize.min, // Centers the Column vertically
              mainAxisAlignment: MainAxisAlignment.center, // Redundant but ensures centering
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildLevelButton(context, 'Level 1', ParkingSpaceScreen1()),
                const SizedBox(height: 20),
                _buildLevelButton(context, 'Level 2', ParkingSpaceScreen2()),
                const SizedBox(height: 20),
                _buildLevelButton(context, 'Level 3', ParkingSpaceScreen3()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelButton(BuildContext context, String level, Widget nextScreen) {
    return GestureDetector(
      onTap: () => _navigateWithFadeTransition(context, nextScreen),
      child: Container(
        height: 150,
        width: 170,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_parking, size: 50, color: Colors.white),
            const SizedBox(height: 10),
            Text(
              level,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20.0),
            ),
          ],
        ),
      ),
    );
  }

  // Fade-in transition with smooth effect
  void _navigateWithFadeTransition(BuildContext context, Widget nextScreen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));
          return FadeTransition(opacity: fadeAnimation, child: child);
        },
      ),
    );
  }
}

























