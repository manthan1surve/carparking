import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login_page.dart'; // Assuming you have this page for login

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isEditing = false; // Flag to track if editing is enabled

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile(); // Fetch user data initially
  }

  Future<void> _fetchUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      DataSnapshot snapshot = await _database.ref('users/${user.uid}').get();
      if (snapshot.exists) {
        var userData = snapshot.value as Map<dynamic, dynamic>;
        _nameController.text = userData['name'] ?? '';
        _phoneController.text = userData['phone'] ?? '';
      }
    }
  }

  Future<void> _saveUserProfile() async {
    User? user = _auth.currentUser;
    if (user != null) {
      await _database.ref('users/${user.uid}').update({
        'name': _nameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
      });

      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Profile updated")));
    }
  }

  Future<void> _logOut() async {
    try {
      await _auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      print("Error during sign out: $e");
    }
  }

  Future<List<Booking>> _fetchPastBookings() async {
    User? user = _auth.currentUser;
    if (user == null) return [];

    DataSnapshot snapshot = await _database.ref('users/${user.uid}/bookings').get();
    if (snapshot.exists) {
      var bookingsData = snapshot.value as Map<dynamic, dynamic>;
      return bookingsData.values.map((booking) => Booking(
        slotName: booking['slotName'] ?? '',
        time: booking['time'] ?? '',
        duration: booking['duration'] ?? '',
      )).toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text('Profile')),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: Colors.black.withOpacity(0.5),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('User Information:', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildTextField(_nameController, 'Name'),
              const SizedBox(height: 10),
              _buildTextField(_emailController, 'Email', enabled: false),
              const SizedBox(height: 10),
              _buildTextField(_phoneController, 'Phone Number'),
              const SizedBox(height: 20),

              // Buttons side by side
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _isEditing ? _saveUserProfile : () => setState(() => _isEditing = true),
                    child: Text(_isEditing ? 'Save Changes' : 'Edit Profile'),
                  ),
                  ElevatedButton(
                    onPressed: _logOut,
                    child: const Text('Log Out'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const Text('Past Bookings:', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // Past bookings list
              Expanded(
                child: FutureBuilder<List<Booking>>(
                  future: _fetchPastBookings(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return const Center(child: Text('Error loading bookings', style: TextStyle(color: Colors.red)));
                    } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final booking = snapshot.data![index];
                          return Card(
                            color: Colors.grey.withOpacity(0.5),
                            elevation: 4,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text('Slot: ${booking.slotName}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text('Duration: ${booking.duration}', style: const TextStyle(color: Colors.white)),
                              trailing: Text(booking.time, style: const TextStyle(color: Colors.white)),
                            ),
                          );
                        },
                      );
                    } else {
                      return const Center(child: Text('No past bookings available', style: TextStyle(color: Colors.white)));
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool enabled = true}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white),
        fillColor: Colors.white.withOpacity(0.1),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0), // Rounded corners
        ),
      ),
      style: const TextStyle(color: Colors.white),
      enabled: enabled,
    );
  }
}

class Booking {
  final String slotName;
  final String time;
  final String duration;

  Booking({
    required this.slotName,
    required this.time,
    required this.duration,
  });
}








