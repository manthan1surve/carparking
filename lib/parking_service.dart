import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class ParkingService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;

  // Function to write parking lot data with levels and spots to Firebase
  Future<void> writeParkingLotData(String lotId, ParkingLot parkingLot) async {
    DatabaseReference lotRef = _database.ref('levels/$lotId');

    // Convert ParkingLot to a map to store it in Firebase
    Map<String, dynamic> lotMap = parkingLot.toMap();

    // Write data to Firebase
    await lotRef.set(lotMap);
  }

  // Function to update the status of a parking spot
  Future<void> updateParkingSpotStatus(
      String lotId,
      String levelId,
      String spotId,
      String status,
      ) async {
    DatabaseReference spotRef =
    _database.ref('levels/$lotId/$levelId/spots/$spotId');

    // Convert status to 1 for available and 0 for occupied
    int statusValue = (status == 'available') ? 1 : 0;

    // Get the current timestamp in ISO 8601 format
    String lastUpdated = DateFormat("yyyy-MM-ddTHH:mm:ssZ").format(DateTime.now());

    // Update the spot status and last updated time
    await spotRef.update({
      'status': statusValue,
      'lastUpdated': lastUpdated,
    });

    // Optionally, update the availability count for the level
    await _updateLevelAvailability(lotId, levelId);
    await _updateLotAvailability(lotId);
  }

  // Function to update available spots in a parking level
  Future<void> _updateLevelAvailability(String lotId, String levelId) async {
    DatabaseReference levelRef = _database.ref('levels/$lotId/$levelId');
    DataSnapshot snapshot = await levelRef.get();

    if (snapshot.exists) {
      Map<String, dynamic> levelData = snapshot.value as Map<String, dynamic>;
      int availableSpots = 0;

      // Count available spots (status == 1 means available)
      levelData['spots'].forEach((key, value) {
        if (value['status'] == 1) {
          availableSpots++;
        }
      });

      // Update available spots in the level
      await levelRef.update({'availableSpots': availableSpots});
    }
  }

  // Function to update available spots in the parking lot
  Future<void> _updateLotAvailability(String lotId) async {
    DatabaseReference lotRef = _database.ref('levels/$lotId');
    DataSnapshot snapshot = await lotRef.get();

    if (snapshot.exists) {
      Map<String, dynamic> lotData = snapshot.value as Map<String, dynamic>;
      int availableSpots = 0;

      // Count available spots across all levels
      lotData.forEach((levelKey, levelValue) {
        if (levelKey != "totalSpots" && levelKey != "availableSpots") {
          availableSpots += (levelValue['availableSpots'] as num).toInt();
        }
      });

      // Update available spots in the lot
      await lotRef.update({'availableSpots': availableSpots});
    }
  }

  // Function to occupy a parking spot (replace booking concept with occupying)
  Future<void> occupyParkingSpot(
      String lotId,
      String levelId,
      String spotId,
      ) async {
    // Check if the spot is available
    bool isSpotAvailable = await _isSpotAvailable(lotId, levelId, spotId);
    if (!isSpotAvailable) {
      throw Exception('The spot is already occupied or unavailable.');
    }

    // Get the current timestamp in ISO 8601 format
    String occupiedAt = DateFormat("yyyy-MM-ddTHH:mm:ssZ").format(DateTime.now());

    // Update spot status to "occupied" and record the occupancy details
    await _updateSpotStatus(lotId, levelId, spotId, 'occupied', occupiedAt);

    // Optionally, update availability counts
    await _updateLevelAvailability(lotId, levelId);
    await _updateLotAvailability(lotId);
  }

  // Function to check if a parking spot is available
  Future<bool> _isSpotAvailable(String lotId, String levelId, String spotId) async {
    DatabaseReference spotRef = _database.ref('levels/$lotId/$levelId/spots/$spotId');
    DataSnapshot snapshot = await spotRef.get();

    if (snapshot.exists) {
      Map<String, dynamic> spotData = snapshot.value as Map<String, dynamic>;
      int status = spotData['status'];
      return status == 1; // 1 means available
    }
    return false;
  }

  // Function to update spot status in "levels"
  Future<void> _updateSpotStatus(
      String lotId,
      String levelId,
      String spotId,
      String status,
      String occupiedAt,
      ) async {
    DatabaseReference spotRef =
    _database.ref('levels/$lotId/$levelId/spots/$spotId');

    int statusValue = (status == 'occupied') ? 0 : 1; // 0 for occupied, 1 for available

    await spotRef.update({
      'status': statusValue,
      'occupiedAt': occupiedAt,
    });
  }
}

// Define the ParkingLot class to handle data structure for parking lots
class ParkingLot {
  final String name;
  final int totalSpots;
  final int availableSpots;
  final Map<String, Level> levels;

  ParkingLot({
    required this.name,
    required this.totalSpots,
    required this.availableSpots,
    required this.levels,
  });

  // Method to convert ParkingLot instance to Map for saving in Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'totalSpots': totalSpots,
      'availableSpots': availableSpots,
      'levels': levels.map((key, level) => MapEntry(key, level.toMap())),
    };
  }
}

// Define the Level class to handle parking levels within a lot
class Level {
  final String name;
  final int totalSpots;
  final int availableSpots;
  final Map<String, Spot> spots;

  Level({
    required this.name,
    required this.totalSpots,
    required this.availableSpots,
    required this.spots,
  });

  // Method to convert Level instance to Map for saving in Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'totalSpots': totalSpots,
      'availableSpots': availableSpots,
      'spots': spots.map((key, spot) => MapEntry(key, spot.toMap())),
    };
  }
}

// Define the Spot class to handle individual parking spots
class Spot {
  final String spotId;
  final int status; // 1 for available, 0 for occupied
  final String? occupiedAt;
  final String lastUpdated;

  Spot({
    required this.spotId,
    required this.status,
    this.occupiedAt,
    required this.lastUpdated,
  });

  // Method to convert Spot instance to Map for saving in Firebase
  Map<String, dynamic> toMap() {
    return {
      'spotId': spotId,
      'status': status,
      'occupiedAt': occupiedAt,
      'lastUpdated': lastUpdated,
    };
  }
}


