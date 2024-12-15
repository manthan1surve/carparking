import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'reservepage.dart'; // Import the ReservePage

class FirebaseService {
  final databaseReference = FirebaseDatabase.instance.ref();

  Stream<DatabaseEvent> getParkingSlotStream(String levelId, String spotId) =>
      databaseReference.child('levels/$levelId/spots/$spotId').onValue;

  Future<void> updateParkingSlotStatus(String levelId, String spotId, int status) async {
    await databaseReference.child('levels/$levelId/spots/$spotId').update({
      'status': status,
      'lastUpdated': DateTime.now().toIso8601String(),
    });
  }
}

class ParkingSpaceScreen3 extends StatefulWidget {
  const ParkingSpaceScreen3({super.key});
  @override
  _ParkingSpaceScreenState3 createState() => _ParkingSpaceScreenState3();
}

class _ParkingSpaceScreenState3 extends State<ParkingSpaceScreen3> {
  final FirebaseService firebaseService = FirebaseService();
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Level 3", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        centerTitle: true,
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
              Text('Select a parking space below:', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: _buildParkingSlotColumn('level3', ['1c', '2c', '3c', '4c'], [1, 2, 3, 4])),
                  const SizedBox(width: 20),
                  Expanded(child: _buildParkingSlotColumn('level3', ['5c', '6c', '7c', '8c'], [5, 6, 7, 8])),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  Widget _buildParkingSlotColumn(String levelId, List<String> spotIds, List<int> spotNumbers) => Column(
    children: List.generate(spotIds.length, (index) => _buildParkingSlot(levelId, spotIds[index], spotNumbers[index])),
  );

  Widget _buildParkingSlot(String levelId, String spotId, int spotNumber) => StreamBuilder<DatabaseEvent>(
    stream: firebaseService.getParkingSlotStream(levelId, spotId),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) return const Center(child: Text('Error fetching data', style: TextStyle(color: Colors.red)));
      if (snapshot.hasData) {
        final data = snapshot.data!.snapshot.value as Map?;
        if (data != null) {
          final status = data['status'];
          final parkingStatus = (status == 1) ? 'Available' : 'Occupied';
          final parkingSpace = (status == 1) ? 1 : -1;
          return _buildSlotCard(parkingSpace, 'Spot $spotNumber', levelId, spotId, parkingStatus);
        } else return const Center(child: Text('No data available'));
      } else return const Center(child: Text('No data available'));
    },
  );

  Widget _buildSlotCard(int parkingSpace, String spotName, String levelId, String spotId, String parkingStatus) => Card(
    color: parkingSpace == 1 ? Colors.green[300] : Colors.red[300],
    elevation: 6,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Text(spotName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          Text(parkingStatus, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          Image.asset(parkingSpace == 1 ? 'assets/images/Green Car.png' : 'assets/images/Red Car.png', width: 100, height: 60),
          const SizedBox(height: 10),
          if (parkingSpace == 1)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReservePage(slotKey: spotId, slotName: spotName),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Reserve', style: TextStyle(fontSize: 16)),
            ),
        ],
      ),
    ),
  );
}

