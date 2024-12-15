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
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  late double deviceWidth, deviceHeight;

  @override
  Widget build(BuildContext context) {
    deviceWidth = MediaQuery.of(context).size.width;
    deviceHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Center(child: Text("", style: TextStyle(fontSize: 25))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          width: deviceWidth,
          height: deviceHeight,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/back.png'),
              fit: BoxFit.contain,
              alignment: Alignment.center,
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 150),
                  _buildLevelButton('Level 1', ParkingSpaceScreen1()),
                  const SizedBox(height: 20),
                  _buildLevelButton('Level 2', ParkingSpaceScreen2()),
                  const SizedBox(height: 20),
                  _buildLevelButton('Level 3', ParkingSpaceScreen3()),
                  const SizedBox(height: 75),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // A helper method to build each level button with smooth transition
  Widget _buildLevelButton(String level, Widget nextScreen) {
    return GestureDetector(
      onTap: () {
        _navigateWithTransition(nextScreen);
      },
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
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Custom transition to slide up the next screen
  void _navigateWithTransition(Widget nextScreen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Slide up transition
          var begin = const Offset(0.0, 1.0); // Start from the bottom
          var end = Offset.zero; // End at the current position
          var curve = Curves.easeInOut; // Smooth curve
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }
}





