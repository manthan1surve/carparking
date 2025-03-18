import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReservePage extends StatefulWidget {
  final String slotKey;
  final String slotName;
  final String levelId;

  const ReservePage({Key? key, required this.slotKey, required this.slotName, required this.levelId})
      : super(key: key);

  @override
  _ReservePageState createState() => _ReservePageState();
}

class _ReservePageState extends State<ReservePage> {
  String selectedDuration = '1 hour';
  String selectedPaymentMethod = 'Credit Card';
  double amountToPay = 5.00;

  final FirebaseDatabase _database = FirebaseDatabase.instance;

  final List<String> durationOptions = ['1 hour', '2 hours', '3 hours', '4 hours'];
  final List<String> paymentMethods = ['Credit Card', 'PayPal', 'Google Pay'];

  // Update amount based on selected duration
  void updateAmount(String duration) {
    final durationMapping = {
      '1 hour': 5.00,
      '2 hours': 10.00,
      '3 hours': 15.00,
      '4 hours': 20.00,
    };
    setState(() {
      amountToPay = durationMapping[duration] ?? 5.00;
    });
  }

  // Reserve parking spot and update database
  Future<void> reserveParkingSpot() async {
    final ref = _database.ref('levels/${widget.levelId}/spots/${widget.slotKey}');
    final currentTime = DateTime.now().toIso8601String();

    // Get current user
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Handle case when user is not logged in
      print('No user is logged in');
      return;
    }

    // Get user ID (Firebase UID)
    String userId = user.uid;

    try {
      // Update the parking spot status to reserved
      await ref.update({
        'status': 0, // Reserved
        'bookedBy': userId, // Store the user ID (not the name directly)
        'bookedAt': currentTime,
      });

      // Update user's booking history
      await _addBookingHistory(userId, widget.slotKey, currentTime);

      // Show confirmation dialog
      _showConfirmationDialog();
    } catch (error) {
      print("Error updating reservation: $error");
    }
  }

  // Add booking history to the user's data
  Future<void> _addBookingHistory(String userId, String spotId, String bookedAt) async {
    DatabaseReference userRef = _database.ref('users/$userId/bookingHistory');

    try {
      await userRef.set({
        'spotId': spotId,
        'bookedAt': bookedAt,
      });
      print('Booking history written to users/$userId/bookingHistory');
    } catch (e) {
      print('Failed to write booking history: $e');
    }
  }

  // Show confirmation dialog
  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reservation Confirmed'),
          content: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'You have successfully reserved ${widget.slotName} for $selectedDuration.\nAmount: ₹${amountToPay.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 16),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close confirmation dialog
                Navigator.pop(context); // Go back to the previous screen
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Build a dropdown widget for selecting duration or payment method
  Widget _buildDropdown(String label, String currentValue, List<String> options, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white, // Background color for rounded container
            borderRadius: BorderRadius.circular(12), // Rounded corners
            boxShadow: [BoxShadow(blurRadius: 4, color: Colors.grey.withOpacity(0.2), spreadRadius: 2)],
          ),
          child: DropdownButton<String>(
            value: currentValue,
            onChanged: onChanged,
            isExpanded: true,
            style: TextStyle(fontSize: 16, color: Colors.black),
            iconSize: 24,
            elevation: 8,
            underline: Container(
              height: 2,
              color: Colors.blueAccent,
            ),
            items: options.map((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Text(value),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reserve Parking - ${widget.slotName}'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Reserve ${widget.slotName}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blueGrey),
            ),
            const SizedBox(height: 20),

            // Duration selection dropdown
            _buildDropdown('Select Parking Duration:', selectedDuration, durationOptions, (value) {
              setState(() {
                selectedDuration = value!;
                updateAmount(selectedDuration);
              });
            }),

            const SizedBox(height: 20),

            // Payment method dropdown
            _buildDropdown('Select Payment Method:', selectedPaymentMethod, paymentMethods, (value) {
              setState(() {
                selectedPaymentMethod = value!;
              });
            }),

            const SizedBox(height: 20),

            // Amount to pay
            Text(
              'Amount to Pay: ₹${amountToPay.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 40),

            // Reserve button
            Center(
              child: ElevatedButton(
                onPressed: reserveParkingSpot,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(vertical: 15, horizontal: 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: const Text('Reserve Now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


