import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'reservepage.dart';

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

class ParkingSpaceScreen2 extends StatelessWidget {
  final FirebaseService firebaseService = FirebaseService();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
          title: const Text("Level 2", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          backgroundColor: Colors.transparent, elevation: 0, centerTitle: true,
        ),
        backgroundColor: Colors.black.withOpacity(0.5),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const SizedBox(height: 30),
                Text('Select a parking space below:', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildParkingSlotColumn('level2', ['1b', '2b', '3b', '4b'], [1, 2, 3, 4]),
                    const SizedBox(width: 20),
                    _buildParkingSlotColumn('level2', ['5b', '6b', '7b', '8b'], [5, 6, 7, 8]),
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
    return Expanded(
      child: Column(
        children: List.generate(spotIds.length, (index) => _buildParkingSlot(levelId, spotIds[index], spotNumbers[index])),
      ),
    );
  }

  Widget _buildParkingSlot(String levelId, String spotId, int spotNumber) {
    return StreamBuilder<DatabaseEvent>(
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
            return _buildSlotCard(parkingSpace, 'Spot $spotNumber', levelId, spotId, parkingStatus, context);
          }
        }
        return const Center(child: Text('No data available'));
      },
    );
  }

  Widget _buildSlotCard(int parkingSpace, String spotName, String levelId, String spotId, String parkingStatus, BuildContext context) {
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
            Image.asset(parkingSpace == 1 ? 'assets/images/Green Car.png' : 'assets/images/Red Car.png', width: 100, height: 60),
            const SizedBox(height: 10),
            if (parkingSpace == 1) ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ReservePage(slotKey: spotId, slotName: spotName,levelId: levelId)));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: const Text('Reserve', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

