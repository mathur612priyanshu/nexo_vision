import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/innerScreens/upload_notes.dart';
import 'package:url_launcher/url_launcher.dart';

class DisplayNotesPage extends StatefulWidget {
  const DisplayNotesPage({super.key});

  @override
  _DisplayNotesPageState createState() => _DisplayNotesPageState();
}

class _DisplayNotesPageState extends State<DisplayNotesPage> {
  /// Function to launch a PDF in the browser
  void _openPDF(String url) async {
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Could not open PDF")));
    }
  }

  Future<bool> isTeacher() async {
    User? user = FirebaseAuth.instance.currentUser;
    String userId = user?.uid ?? "null";
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    String role = userDoc.exists ? userDoc['role'] : "Student";
    return role == "Teacher";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Notes",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey,
        iconTheme: const IconThemeData(
          color: Colors.white, // Change this to any color you want
        ),
        actions: [
          FutureBuilder<bool>(
            future: isTeacher(), // Call the async function
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(); // Show nothing while loading
              }
              if (snapshot.hasData && snapshot.data == true) {
                return IconButton(
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => UploadNotesPage()));
                  },
                  icon: const Icon(
                    Icons.add,
                    size: 30,
                    weight: 700,
                    color: Colors.white,
                  ),
                );
              }
              return const SizedBox(); // Return empty space if not a teacher
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notes_files')
            .orderBy('uploaded_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notes available."));
          }

          var notes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              var note = notes[index];
              return Card(
                margin: const EdgeInsets.all(10),
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  title: Text(
                      "${note['subject_name']} (${note['subject_code']})",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Uploader: ${note['uploader_name']}",
                          style: const TextStyle(color: Colors.black87)),
                      Text("Course Year: ${note['course_year']}",
                          style: const TextStyle(color: Colors.black87)),
                      Text(
                          "Uploaded on: ${note['uploaded_at'].toDate().toLocal()}"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        onPressed: () => _openPDF(note['file_url']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.download, color: Colors.green),
                        onPressed: () => _openPDF(note['file_url']),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
