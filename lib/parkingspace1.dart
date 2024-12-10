import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'reservepage.dart'; // Import the ReservePage

class FirebaseService {
  final databaseReference = FirebaseDatabase.instance.ref();

  // Fetch the parking slot status stream for a specific level and spot
  Stream<DatabaseEvent> getParkingSlotStream(String levelId, String spotId) {
    return databaseReference
        .child('levels/$levelId/spots/$spotId')
        .onValue;
  }

  // Update the parking slot status in Firebase
  Future<void> updateParkingSlotStatus(String levelId, String spotId, int status) async {
    await databaseReference
        .child('levels/$levelId/spots/$spotId')
        .update({'status': status, 'lastUpdated': DateTime.now().toIso8601String()});
  }
}

class ParkingSpaceScreen1 extends StatefulWidget {
  const ParkingSpaceScreen1({super.key});

  @override
  State<ParkingSpaceScreen1> createState() => _ParkingSpaceScreenState();
}

class _ParkingSpaceScreenState extends State<ParkingSpaceScreen1> {
  final FirebaseService firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Center(child: Text("Parking Spaces", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold))),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        backgroundColor: Colors.black.withOpacity(0.5),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Text(
                  'Select a parking space below:',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left Column with 4 spots (Spot 1 to Spot 4)
                    Expanded(
                      child: _buildParkingSlotColumn('level1', [
                        '1680392789000', '1680392795000', '1680392801000', '1680392807000'
                      ], [1, 2, 3, 4]),  // Mapping Spot 1 to Spot 4 for the left column
                    ),
                    const SizedBox(width: 20),
                    // Right Column with 4 spots (Spot 5 to Spot 8)
                    Expanded(
                      child: _buildParkingSlotColumn('level1', [
                        '1680392812000', '1680392818000', '1680392824000', '1680392830000'
                      ], [5, 6, 7, 8]),  // Mapping Spot 5 to Spot 8 for the right column
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParkingSlotColumn(String levelId, List<String> spotIds, List<int> spotNumbers) {
    return Column(
      children: List.generate(spotIds.length, (index) {
        return _buildParkingSlot(levelId, spotIds[index], spotNumbers[index]);
      }),
    );
  }

  Widget _buildParkingSlot(String levelId, String spotId, int spotNumber) {
    return StreamBuilder<DatabaseEvent>(
      stream: firebaseService.getParkingSlotStream(levelId, spotId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text('Error fetching data', style: TextStyle(color: Colors.red)));
        } else if (snapshot.hasData) {
          final data = snapshot.data!.snapshot.value as Map?;
          if (data != null) {
            final status = data['status']; // It will be either 1 or 0
            final spotName = 'Spot $spotNumber'; // Use spot number for display

            // Convert the status to 'Available' or 'Occupied'
            String parkingStatus = (status == 1) ? 'Available' : 'Occupied';
            int parkingSpace = (status == 1) ? 1 : -1;

            return _buildSlotCard(parkingSpace, spotName, levelId, spotId, parkingStatus);
          } else {
            return const Center(child: Text('No data available'));
          }
        } else {
          return const Center(child: Text('No data available'));
        }
      },
    );
  }

  Widget _buildSlotCard(int parkingSpace, String spotName, String levelId, String spotId, String parkingStatus) {
    return Card(
      color: parkingSpace == 1 ? Colors.green[300] : Colors.red[300],
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(spotName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            Text(parkingStatus, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            Image.asset(
              parkingSpace == 1 ? 'assets/images/Green Car.png' : 'assets/images/Red Car.png',
              width: 100, height: 60,
            ),
            const SizedBox(height: 10),
            if (parkingSpace == 1) ...[
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReservePage(
                        slotKey: spotId, // Pass the spotId (slotKey) to the ReservePage
                        slotName: spotName, // Pass the spot name
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Reserve', style: TextStyle(fontSize: 16)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}



