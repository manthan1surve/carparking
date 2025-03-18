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

class ParkingSpaceScreen1 extends StatelessWidget {
  final FirebaseService firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
          title: Text("Level 1", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        backgroundColor: Colors.black.withOpacity(0.9),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 30),
                Text('Select a parking space below:', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildParkingSlotColumn('level1', ['1a', '2a', '3a', '4a'], [1, 2, 3, 4]),
                    _buildParkingSlotColumn('level1', ['5a', '6a', '7a', '8a'], [5, 6, 7, 8]),
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
        children: List.generate(
          spotIds.length,
              (index) => _buildParkingSlot(levelId, spotIds[index], spotNumbers[index]),
        ),
      ),
    );
  }

  Widget _buildParkingSlot(String levelId, String spotId, int spotNumber) {
    return StreamBuilder<DatabaseEvent>(
      stream: firebaseService.getParkingSlotStream(levelId, spotId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator(color: Colors.blue));
        if (snapshot.hasError) return Center(child: Text('Error fetching data', style: TextStyle(color: Colors.red, fontSize: 16)));
        if (snapshot.hasData) {
          final data = snapshot.data!.snapshot.value as Map?;
          if (data != null) {
            final status = data['status'];
            final parkingStatus = (status == 1) ? 'Available' : 'Occupied';
            final parkingSpace = (status == 1) ? 1 : -1;
            return _buildSlotCard(parkingSpace, 'Spot $spotNumber', levelId, spotId, parkingStatus, context);
          }
        }
        return Center(child: Text('No data available', style: TextStyle(color: Colors.white, fontSize: 16)));
      },
    );
  }

  Widget _buildSlotCard(int parkingSpace, String spotName, String levelId, String spotId, String parkingStatus, BuildContext context) {
    return Card(
      color: parkingSpace == 1 ? Colors.green[300] : Colors.red[300],
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(spotName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 10),
            Text(parkingStatus, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(height: 10),
            Image.asset(parkingSpace == 1 ? 'assets/images/Green Car.png' : 'assets/images/Red Car.png', width: 100, height: 60),
            SizedBox(height: 10),
            if (parkingSpace == 1) ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ReservePage(slotKey: spotId, slotName: spotName, levelId: levelId)));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text('Reserve', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}









