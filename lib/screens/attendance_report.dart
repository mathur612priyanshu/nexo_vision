import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/innerScreens/attendance_screen.dart';
import 'package:intl/intl.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  _AttendanceReportScreenState createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  DateTime _selectedDate = DateTime.now(); // Default to today's date
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String _formattedDate;
  late List<Map<String, dynamic>> _attendanceRecords;

  @override
  void initState() {
    super.initState();
    _formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    _attendanceRecords = [];
    _fetchAttendanceData();
  }

  // Fetch attendance data for the selected date
  Future<void> _fetchAttendanceData() async {
    try {
      // Query Firestore for records that match the selected date
      QuerySnapshot snapshot = await _firestore
          .collection('attendance')
          .where('date', isEqualTo: _formattedDate)
          .get();

      setState(() {
        _attendanceRecords = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      setState(() {
        _attendanceRecords = [];
      });
    }
  }

  // Open a date picker dialog
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      });
      _fetchAttendanceData(); // Refresh attendance data
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50], // Light blue-grey background
      appBar: AppBar(
        title: const Text(
          "Attendance Report",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        // centerTitle: true,
        backgroundColor: Colors.blueGrey,
        elevation: 5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selection Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Select Date:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(
                    DateFormat('EEE, MMM d, yyyy').format(_selectedDate),
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blueGrey[700],
                    side: BorderSide(color: Colors.blueGrey[600]!),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Attendance Data Display
            Expanded(
              child: _attendanceRecords.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.info_outline,
                              size: 50, color: Colors.blueGrey[400]),
                          const SizedBox(height: 10),
                          const Text(
                            "No attendance data available.",
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _attendanceRecords.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> record = _attendanceRecords[index];
                        String name = record['name'] ?? 'Unknown';
                        String rollNumber = record['roll_number'] ?? 'N/A';

                        return Card(
                          color: Colors.blueGrey[100], // Card color
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 16),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blueGrey[700],
                              child:
                                  const Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              'Roll No: $rollNumber',
                              style: TextStyle(color: Colors.blueGrey[900]),
                            ),
                            trailing: const Icon(Icons.check_circle,
                                color: Colors.green),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 20),

            // Mark Attendance Button (Properly Positioned)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const MarkAttendanceScreen()),
                  );
                },
                icon: const Icon(
                  Icons.check,
                  size: 20,
                  color: Colors.white,
                ),
                label: const Text("Mark Attendance"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey, // Button color
                  foregroundColor: Colors.white, // Text color
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
