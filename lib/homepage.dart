import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:iotbasedparking/parkingspace1.dart';
import 'package:iotbasedparking/parkingspace2.dart';
import 'package:iotbasedparking/parkingspace3.dart';

import 'package:iotbasedparking/profile.dart'; // Import Profile screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const Homepage(),
    );
  }
}

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  late double deviceWidth;
  late double deviceHeight;

  @override
  Widget build(BuildContext context) {
    deviceWidth = MediaQuery.of(context).size.width;
    deviceHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Center(
          child: Text(
            "Park-A-Lot",
            style: TextStyle(fontSize: 25),
          ),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.black.withOpacity(0.3),
      body: Center(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              tileMode: TileMode.mirror,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(133, 193, 193, 193),
                Color.fromARGB(0, 81, 80, 80),
              ],
            ),
          ),
          child: SizedBox(
            height: deviceHeight,
            width: deviceWidth,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 150),
                    // Level 1 Button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ParkingSpaceScreen1()),
                        );
                      },
                      child: _buildLevelButton('Level 1'),
                    ),
                    const SizedBox(height: 20),
                    // Level 2 Button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ParkingSpaceScreen2()),
                        );
                      },
                      child: _buildLevelButton('Level 2'),
                    ),
                    const SizedBox(height: 20),
                    // Level 3 Button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ParkingSpaceScreen3()),
                        );
                      },
                      child: _buildLevelButton('Level 3'),
                    ),
                    const SizedBox(height: 75),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // A helper method to build each level button
  Widget _buildLevelButton(String level) {
    return Container(
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
          Icon(
            Icons.local_parking,
            size: 50,
            color: Colors.white,
          ),
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
    );
  }
}



