import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class ParkingService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to reserve a parking spot and add booking to history
  Future<void> reserveParkingSpot(String levelId, String spotId) async {
    String userId = _auth.currentUser?.uid ?? 'anonymous';
    String userEmail = _auth.currentUser?.email ?? 'anonymous@example.com';

    if (userId == 'anonymous') {
      throw Exception('User is not logged in');
    }

    String bookedAt = DateFormat("yyyy-MM-ddTHH:mm:ssZ").format(DateTime.now());

    DatabaseReference spotRef = _database.ref('levels/$levelId/spots/$spotId');
    DataSnapshot spotSnapshot = await spotRef.get();

    if (spotSnapshot.exists) {
      Map<String, dynamic> spotData = spotSnapshot.value as Map<String, dynamic>;

      if (spotData['status'] == 0) {
        throw Exception('The spot is already booked.');
      }

      await spotRef.update({
        'status': 0,
        'bookedBy': userId,
        'bookedAt': bookedAt,
        'lastUpdated': bookedAt,
      });

      try {
        await _addBookingHistory(userId, userEmail, levelId, spotId, bookedAt);
        print('Booking history updated successfully for user $userId');
      } catch (e) {
        print('Error updating booking history: $e');
        throw Exception('Failed to update booking history.');
      }

      await _updateLevelAvailability(levelId);
    }
  }

  Future<void> _addBookingHistory(String userId, String userEmail, String levelId, String spotId, String bookedAt) async {
    DatabaseReference userRef = _database.ref('users/$userId/bookingHistory');

    print('Adding booking history for user $userId (email: $userEmail):');
    print({
      'levelId': levelId,
      'spotId': spotId,
      'bookedAt': bookedAt,
    });

    try {
      await userRef.set({
        'levelId': levelId,
        'spotId': spotId,
        'bookedAt': bookedAt,
        'userEmail': userEmail,
      });
      print('Booking history written to users/$userId/bookingHistory');
    } catch (e) {
      print('Failed to write booking history: $e');
      throw Exception('Failed to update booking history.');
    }

    if (userEmail.isNotEmpty) {
      DatabaseReference userEmailRef = _database.ref('users/$userId/email');
      await userEmailRef.set(userEmail);
      print('User email written to users/$userId/email');
    } else {
      print("User email is empty. Skipping email update.");
    }
  }

  Future<void> _updateLevelAvailability(String levelId) async {
    DatabaseReference levelRef = _database.ref('levels/$levelId');
    DataSnapshot snapshot = await levelRef.get();

    if (snapshot.exists) {
      Map<String, dynamic> levelData = snapshot.value as Map<String, dynamic>;
      int availableSpots = 0;

      levelData['spots'].forEach((key, value) {
        if (value['status'] == 1) {
          availableSpots++;
        }
      });

      await levelRef.update({'availableSpots': availableSpots});
    }
  }

  Future<bool> isSpotAvailable(String levelId, String spotId) async {
    DatabaseReference spotRef = _database.ref('levels/$levelId/spots/$spotId');
    DataSnapshot snapshot = await spotRef.get();

    if (snapshot.exists) {
      Map<String, dynamic> spotData = snapshot.value as Map<String, dynamic>;
      return spotData['status'] == 1;
    }
    return false;
  }

  Future<void> logOut() async {
    await _auth.signOut();
    print('User has logged out. Data remains intact.');
  }
}


