import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

// FirebaseService to interact with Firebase Database
class FirebaseService {
  final databaseReference = FirebaseDatabase.instance.ref();

  // Fetch the parking slot status
  Future<Map?> getParkingSlot(String slotKey) async {
    final snapshot = await databaseReference.child('parkingLots/$slotKey').get();
    return snapshot.value as Map?;
  }

  // Update parking slot status
  Future<void> updateParkingSlot(String slotKey, String status, String bookedBy) async {
    await databaseReference.child('parkingLots/$slotKey').update({
      'status': status,
      'bookedBy': bookedBy,
      'bookedAt': DateTime.now().toIso8601String(),
    });
  }
}

class ReservePage extends StatefulWidget {
  final String slotKey;
  final String slotName;

  const ReservePage({super.key, required this.slotKey, required this.slotName});

  @override
  _ReservePageState createState() => _ReservePageState();
}

class _ReservePageState extends State<ReservePage> {
  final FirebaseService firebaseService = FirebaseService();
  String selectedDuration = '1 Hour';
  String selectedPayment = 'Credit Card';
  bool isSlotAvailable = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _checkSlotAvailability();
  }

  // Check if the parking slot is available
  Future<void> _checkSlotAvailability() async {
    try {
      final data = await firebaseService.getParkingSlot(widget.slotKey);
      if (data != null && data['status'] == 'available') {
        setState(() {
          isSlotAvailable = true;
          errorMessage = ''; // Reset error message if available
        });
      } else {
        setState(() {
          isSlotAvailable = false;
          errorMessage = 'This parking spot is already reserved or occupied.';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching slot data: $e';
      });
    }
  }

  // Reserve the parking spot
  Future<void> _reserveSpot() async {
    try {
      await firebaseService.updateParkingSlot(widget.slotKey, 'booked', 'User123'); // Replace 'User123' with dynamic username
      Navigator.pop(context); // Go back after reservation
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Success'),
          content: Text('Your spot has been successfully reserved.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        errorMessage = 'Error reserving the spot: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Reserve ${widget.slotName}')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Slot: ${widget.slotName}', style: TextStyle(fontSize: 24)),
              SizedBox(height: 20),
              if (isSlotAvailable) ...[
                Text('This parking spot is available!', style: TextStyle(fontSize: 18)),
                // Display form to allow the user to reserve
                DropdownButton<String>(
                  value: selectedDuration,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedDuration = newValue!;
                    });
                  },
                  items: ['1 Hour', '2 Hours', '3 Hours', 'Full Day']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                SizedBox(height: 10),
                DropdownButton<String>(
                  value: selectedPayment,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedPayment = newValue!;
                    });
                  },
                  items: ['Credit Card', 'Debit Card', 'PayPal']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _reserveSpot,
                  child: Text('Reserve Now'),
                ),
              ] else ...[
                Text(errorMessage, style: TextStyle(fontSize: 18, color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}




