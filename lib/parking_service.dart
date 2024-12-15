import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class ParkingService {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to reserve a parking spot and add booking to history
  Future<void> reserveParkingSpot(
      String levelId,
      String spotId,
      ) async {
    // Fetch the current user's userId and email
    String userId = _auth.currentUser?.uid ?? 'anonymous';  // Get userId from Firebase Authentication
    String userEmail = _auth.currentUser?.email ?? 'anonymous@example.com';  // Get user email

    // Check if the user is logged in
    if (userId == 'anonymous') {
      throw Exception('User is not logged in');
    }

    // Get current timestamp
    String bookedAt = DateFormat("yyyy-MM-ddTHH:mm:ssZ").format(DateTime.now());

    // Reference to the spot in the database
    DatabaseReference spotRef = _database.ref('levels/$levelId/spots/$spotId');

    // Get the current spot data
    DataSnapshot spotSnapshot = await spotRef.get();

    if (spotSnapshot.exists) {
      Map<String, dynamic> spotData = spotSnapshot.value as Map<String, dynamic>;

      // Check if the spot is already booked
      if (spotData['status'] == 0) {
        throw Exception('The spot is already booked.');
      }

      // Update the spot status to "booked" and set booking details
      await spotRef.update({
        'status': 0, // 0 for occupied
        'bookedBy': userId,
        'bookedAt': bookedAt,
        'lastUpdated': bookedAt,
      });

      // Add the booking to the user's booking history
      try {
        await _addBookingHistory(userId, userEmail, levelId, spotId, bookedAt);
        print('Booking history updated successfully for user $userId');
      } catch (e) {
        print('Error updating booking history: $e');
        throw Exception('Failed to update booking history.');
      }

      // Optionally, update the available spots count in the level
      await _updateLevelAvailability(levelId);
    }
  }

  // Function to add booking history for a user (including email)
  Future<void> _addBookingHistory(
      String userId,
      String userEmail,
      String levelId,
      String spotId,
      String bookedAt,
      ) async {
    DatabaseReference userRef = _database.ref('users/$userId/bookingHistory/$spotId');

    // Debugging: Log data before writing
    print('Adding booking history for user $userId (email: $userEmail):');
    print({
      'levelId': levelId,
      'spotId': spotId,
      'bookedAt': bookedAt,
    });

    try {
      // Add the reservation details to the user's booking history
      await userRef.set({
        'levelId': levelId,
        'spotId': spotId,
        'bookedAt': bookedAt,
        'userEmail': userEmail, // Include the user's email
      });
      print('Booking history written to users/$userId/bookingHistory/$spotId');
    } catch (e) {
      print('Failed to write booking history: $e');
      throw Exception('Failed to update booking history.');
    }

    // Now, write the user's email if it's not empty
    if (userEmail.isNotEmpty) {
      DatabaseReference userEmailRef = _database.ref('users/$userId/email');
      await userEmailRef.set(userEmail); // Save the user's email under the userId node
      print('User email written to users/$userId/email');
    } else {
      print("User email is empty. Skipping email update.");
    }
  }

  // Function to update available spots in a parking level
  Future<void> _updateLevelAvailability(String levelId) async {
    DatabaseReference levelRef = _database.ref('levels/$levelId');
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

  // Function to check if a parking spot is available
  Future<bool> isSpotAvailable(String levelId, String spotId) async {
    DatabaseReference spotRef = _database.ref('levels/$levelId/spots/$spotId');
    DataSnapshot snapshot = await spotRef.get();

    if (snapshot.exists) {
      Map<String, dynamic> spotData = snapshot.value as Map<String, dynamic>;
      return spotData['status'] == 1; // 1 means available
    }
    return false;
  }

  // Function to handle user logout without deleting data
  Future<void> logOut() async {
    // Sign the user out of Firebase Authentication
    await _auth.signOut();
    // Ensure no data is deleted from the database when the user logs out
    print('User has logged out. Data remains intact.');
  }
}

