import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false; // Track if the user is in editing mode
  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instance;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  // Fetch the user profile data from Firebase Realtime Database
  Future<void> _fetchUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';  // Email fetched from FirebaseAuth (can't be changed by user)
      final snapshot = await _database.ref('users/${user.uid}').get();
      if (snapshot.exists) {
        final userData = snapshot.value as Map;
        _nameController.text = userData['name'] ?? '';
        _phoneController.text = userData['phone'] ?? '';
      }
    }
  }

  // Save the updated user profile information to Firebase
  Future<void> _saveUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _database.ref('users/${user.uid}').update({
        'name': _nameController.text, // Save name
        'phone': _phoneController.text, // Save phone number
      });

      setState(() => _isEditing = false); // Exit editing mode after saving
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated")));
    }
  }

  // Log out and navigate to the login page
  Future<void> _logOut() async {
    await _auth.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  // Fetch the past bookings of the user
  Future<List<Booking>> _fetchPastBookings() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _database.ref('users/${user.uid}/bookings').get();
      if (snapshot.exists) {
        final bookingsData = snapshot.value as Map;
        return bookingsData.values.map((b) => Booking(slotName: b['slotName'], time: b['time'], duration: b['duration'])).toList();
      }
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
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
      ),
      backgroundColor: Colors.black.withOpacity(0.6),
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
              _buildTextField(_emailController, 'Email', enabled: false), // Email is not editable
              const SizedBox(height: 10),
              _buildTextField(_phoneController, 'Phone Number'),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _isEditing ? _saveUserProfile : () => setState(() => _isEditing = true), // Toggle editing mode
                    child: Text(_isEditing ? 'Save Changes' : 'Edit Profile'),
                  ),
                  ElevatedButton(
                    onPressed: _logOut,
                    child: const Text('Log Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const Text('Past Bookings:', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
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
                    }
                    return const Center(child: Text('No past bookings available', style: TextStyle(color: Colors.white)));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Text field for user information
  Widget _buildTextField(TextEditingController controller, String label, {bool enabled = true}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white),
        fillColor: Colors.white.withOpacity(0.1),
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
      ),
      style: const TextStyle(color: Colors.white),
      enabled: enabled && _isEditing, // Enable only when editing
    );
  }
}

// Booking model for past bookings
class Booking {
  final String slotName;
  final String time;
  final String duration;

  Booking({required this.slotName, required this.time, required this.duration});
}
