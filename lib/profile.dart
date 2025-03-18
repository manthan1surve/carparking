import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'login_page.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instance;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isEditing = false;

  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(_controller);
    _controller.forward();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      final snapshot = await _database.ref('users/${user.uid}').get();
      if (snapshot.exists) {
        final userData = snapshot.value as Map;
        _nameController.text = userData['name'] ?? '';
        _phoneController.text = userData['phone'] ?? '';
      }
    }
  }

  Future<void> _saveUserProfile() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _database.ref('users/${user.uid}').update({
        'name': _nameController.text,
        'phone': _phoneController.text,
      });
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated")));
    }
  }

  Future<void> _logOut() async {
    await _auth.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  Future<List<Booking>> _fetchPastBookings() async {
    final user = _auth.currentUser;
    if (user != null) {
      final snapshot = await _database.ref('users/${user.uid}/bookingHistory').get();
      if (snapshot.exists) {
        final bookingHistory = snapshot.value as Map;
        return bookingHistory.values.map((booking) {
          final bookingMap = booking as Map;
          final spotId = bookingMap['spotId'] ?? 'Unknown';
          return Booking(
            slotName: _convertSpotIdToLevelAndSlot(spotId),
            time: _formatDateTime(bookingMap['bookedAt'] ?? 'Unknown'),
            duration: 'N/A',
          );
        }).toList();
      }
    }
    return [];
  }

  String _convertSpotIdToLevelAndSlot(String spotId) {
    final levelChar = spotId[spotId.length - 1];
    final slot = spotId.substring(0, spotId.length - 1);
    final levelNumber = levelChar == 'a' ? 1 : levelChar == 'b' ? 2 : 3;
    return 'Spot $slot of Level $levelNumber';
  }

  String _formatDateTime(String timestamp) {
    if (timestamp == 'Unknown') return 'Unknown';
    return DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.parse(timestamp));
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
      backgroundColor: Colors.black.withOpacity(0.6),
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 13)),
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
                        return const Center(child: Text('Error loading bookings', style: TextStyle(color: Colors.red, fontSize: 18)));
                      } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        return ListView.separated(
                          itemCount: snapshot.data!.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final booking = snapshot.data![index];
                            return Card(
                              color: Colors.grey.shade900,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              elevation: 5,
                              margin: const EdgeInsets.symmetric(horizontal: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(booking.slotName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                    const SizedBox(height: 8),
                                    Text('Time: ${booking.time}', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    Text('Duration: ${booking.duration}', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }
                      return const Center(child: Text('No past bookings available', style: TextStyle(color: Colors.white, fontSize: 16)));
                    },
                  ),
                ),
              ],
            ),
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
        labelStyle: const TextStyle(color: Colors.white),
        fillColor: Colors.white.withOpacity(0.1),
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.0)),
      ),
      style: const TextStyle(color: Colors.white),
      enabled: enabled && _isEditing,
    );
  }
}
class Booking {
  final String slotName;
  final String time;
  final String duration;
  Booking({required this.slotName, required this.time, required this.duration});
}

