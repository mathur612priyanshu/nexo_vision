import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/innerScreens/upload_pyq_page.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class PYQListPage extends StatefulWidget {
  const PYQListPage({super.key});

  @override
  _PYQListPageState createState() => _PYQListPageState();
}

class _PYQListPageState extends State<PYQListPage> {
  /// Function to download the file and open it
  Future<void> _downloadFile(String url, String fileName) async {
    try {
      final dir = await getExternalStorageDirectory();
      String filePath = '${dir!.path}/$fileName.pdf';

      Dio dio = Dio();
      await dio.download(url, filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Downloaded to $filePath")),
      );

      OpenFile.open(filePath);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Download failed: $e")),
      );
    }
  }

  /// Function to open the PDF in the browser
  void _viewPDF(String pdfUrl) async {
    if (await canLaunch(pdfUrl)) {
      await launch(pdfUrl);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open the PDF")),
      );
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
          "Previous Year Questions",
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
                            builder: (context) => UploadPYQPage()));
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
        stream: FirebaseFirestore.instance.collection('pyq_files').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No PYQ files uploaded yet"));
          }

          var pyqList = snapshot.data!.docs;

          return ListView.builder(
            itemCount: pyqList.length,
            itemBuilder: (context, index) {
              var data = pyqList[index].data() as Map<String, dynamic>;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(
                      "${data['subject_name']} (${data['subject_code']})",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Uploader: ${data['uploader_name']}"),
                      Text("Paper Year: ${data['paper_year']}"),
                      Text("Course Year: ${data['course_year']}"),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility, color: Colors.blue),
                        onPressed: () => _viewPDF(data['file_url']),
                      ),
                      IconButton(
                        icon: const Icon(Icons.download, color: Colors.green),
                        onPressed: () => _downloadFile(
                            data['file_url'], data['subject_name']),
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
