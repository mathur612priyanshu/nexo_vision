import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TeacherListScreen extends StatefulWidget {
  const TeacherListScreen({super.key});

  @override
  _TeacherListScreenState createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends State<TeacherListScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _teachers = [];

  @override
  void initState() {
    super.initState();
    _fetchTeacherDetails();
  }

  // Fetch teacher data from Firestore
  Future<void> _fetchTeacherDetails() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'Teacher') // Filter by role 'teacher'
          .get();

      setState(() {
        _teachers = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    } catch (e) {
      print("Error fetching teacher details: $e");
      setState(() {
        _teachers = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Teachers List",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.blueGrey, // Set the AppBar color to blue-grey
        // centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Teacher details display
            _teachers.isEmpty
                ? const Expanded(
                    child: Center(
                      child: Text(
                        "No teachers found.",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  )
                : Expanded(
                    child: ListView.builder(
                      itemCount: _teachers.length,
                      itemBuilder: (context, index) {
                        Map<String, dynamic> teacher = _teachers[index];
                        String name = teacher['name'] ?? 'Unknown';
                        String subject = teacher['subject'] ?? 'N/A';
                        String department = teacher['department'] ?? 'N/A';
                        String email = teacher['email'] ?? 'N/A';
                        String phone = teacher['phone'] ?? 'N/A';

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            // tileColor: const Color.fromARGB(50, 96, 125, 139),
                            contentPadding: const EdgeInsets.all(16),
                            title: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:
                                    Colors.blueGrey, // Title color to blue-grey
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 5),
                                Text(
                                  'Subject: $subject',
                                  style: TextStyle(
                                      color: Colors.blueGrey[
                                          600]), // Subtitle color to blue-grey
                                ),
                                Text(
                                  'Department: $department',
                                  style: TextStyle(color: Colors.blueGrey[600]),
                                ),
                                Text(
                                  'Email: $email',
                                  style: TextStyle(color: Colors.blueGrey[600]),
                                ),
                                Text(
                                  'Mobile no.: $phone',
                                  style: TextStyle(color: Colors.blueGrey[600]),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
