import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/innerScreens/register_face.dart';
import 'package:intl/intl.dart';

/// AttendanceStatusPage - Displays the user's attendance status for the current day.
/// Uses Firebase Firestore to fetch the attendance details.
class AttendanceStatusPage extends StatefulWidget {
  const AttendanceStatusPage({super.key});

  @override
  _AttendanceStatusPageState createState() => _AttendanceStatusPageState();
}

class _AttendanceStatusPageState extends State<AttendanceStatusPage> {
  // Firebase Authentication instance to get current user details.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Future variable to store attendance status
  late Future<String> _attendanceStatus;

  @override
  void initState() {
    super.initState();
    // Fetch attendance status when the page loads
    _attendanceStatus = _getAttendanceStatus();
  }

  /// Fetches the attendance status for the logged-in user.
  /// Returns 'Present' if attendance exists for today, 'Absent' otherwise.
  Future<String> _getAttendanceStatus() async {
    String? userId = _auth.currentUser?.uid;

    // If the user is not logged in, return an error message
    if (userId == null) {
      return 'User not logged in.';
    }

    try {
      // Get the current date in 'yyyy-MM-dd' format
      String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      // Query Firestore to check if attendance exists for the current day
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('attendance') // Access the attendance collection
          .where('user_id', isEqualTo: userId) // Filter by current user ID
          .where('date', isEqualTo: formattedDate) // Filter by today's date
          .get();

      // If no attendance record is found, return 'Absent', otherwise 'Present'
      return snapshot.docs.isEmpty ? 'Absent' : 'Present';
    } catch (e) {
      // Handle errors by returning 'Error' status
      return 'Error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50], // Light BlueGrey background
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          "Attendance Status",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey, // Consistent with home page theme
        elevation: 2, // Slight shadow effect for better UI
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Adds spacing around content
          child: FutureBuilder<String>(
            future: _attendanceStatus, // Fetches attendance status
            builder: (context, snapshot) {
              // Show a loading indicator while fetching data
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }

              // Get attendance status from the snapshot (default to 'Error' if null)
              String status = snapshot.data ?? 'Error';

              // Define colors and icons based on attendance status
              Color statusColor =
                  status == 'Present' ? Colors.green : Colors.red;
              IconData statusIcon =
                  status == 'Present' ? Icons.check_circle : Icons.cancel;

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title text for attendance status
                  Text(
                    'Your Attendance Status:',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey[900],
                    ),
                  ),
                  const SizedBox(height: 20), // Space between elements

                  // Card displaying attendance status
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(15)), // Rounded corners
                    elevation: 5, // Adds shadow effect
                    color: Colors.white, // Card background color
                    shadowColor:
                        Colors.blueGrey.withOpacity(0.5), // Soft shadow
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Icon(statusIcon,
                              color: statusColor,
                              size: 80), // Attendance status icon
                          const SizedBox(height: 10),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: statusColor, // Text color based on status
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30), // Spacing

                  // Register Face Button
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to the Register Face screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RegisterFaceScreen()),
                      );
                    },
                    icon: const Icon(
                      Icons.face,
                      color: Colors.white,
                    ), // Face icon
                    label: const Text(
                      "Register Your Face",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey, // Button color
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12), // Button padding
                      textStyle:
                          const TextStyle(fontSize: 18), // Button text size
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              10)), // Rounded button shape
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
