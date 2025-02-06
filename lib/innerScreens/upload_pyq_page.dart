import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class UploadPYQPage extends StatefulWidget {
  const UploadPYQPage({super.key});

  @override
  _UploadPYQPageState createState() => _UploadPYQPageState();
}

class _UploadPYQPageState extends State<UploadPYQPage> {
  final _formKey = GlobalKey<FormState>();
  File? selectedPDF;
  String? downloadUrl;
  String subjectName = "";
  String subjectCode = "";
  String courseYear = "";
  String paperYear = "";
  bool isUploading = false;

  // Pick PDF File
  Future<void> pickPDF() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        selectedPDF = File(result.files.single.path!);
      });
    }
  }

  // Upload PDF to Cloudinary
  Future<void> uploadPDF() async {
    if (!_formKey.currentState!.validate() || selectedPDF == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all fields and select a PDF')),
      );
      return;
    }

    setState(() => isUploading = true);

    String cloudName = dotenv.env['CLOUD_NAME']!;
    String uploadPreset = dotenv.env['UPLOAD_PRESET']!;

    var uri =
        Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/raw/upload");

    var request = http.MultipartRequest("POST", uri)
      ..fields["upload_preset"] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath(
        "file",
        selectedPDF!.path,
        contentType: MediaType.parse(
            lookupMimeType(selectedPDF!.path) ?? 'application/pdf'),
      ));

    var response = await request.send();

    if (response.statusCode == 200) {
      final respBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(respBody);
      downloadUrl = jsonResponse["secure_url"];

      await saveFileToFirestore(downloadUrl!);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload successful!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload failed! Please try again.')),
      );
    }

    setState(() => isUploading = false);
  }

  // Save PDF details to Firestore
  Future<void> saveFileToFirestore(String url) async {
    User? user = FirebaseAuth.instance.currentUser;
    String userId = user?.uid ?? "null";
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    String uploaderName = userDoc.exists ? userDoc['name'] : "Unknown User";

    await FirebaseFirestore.instance.collection("pyq_files").add({
      "subject_name": subjectName,
      "subject_code": subjectCode,
      "course_year": courseYear,
      "paper_year": paperYear,
      "file_url": url,
      "uploader_name": uploaderName,
      "uploaded_at": DateTime.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Upload PYQ PDF",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.blueGrey, // Set AppBar color to blue-grey
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject Name Field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Subject Name",
                    filled: true,
                    fillColor:
                        Colors.blueGrey[50], // Light background for fields
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? "Required" : null,
                  onChanged: (value) => subjectName = value,
                ),
                const SizedBox(height: 15),

                // Subject Code Field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Subject Code",
                    filled: true,
                    fillColor: Colors.blueGrey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? "Required" : null,
                  onChanged: (value) => subjectCode = value,
                ),
                const SizedBox(height: 15),

                // Course Year Field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Course Year",
                    filled: true,
                    fillColor: Colors.blueGrey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? "Required" : null,
                  onChanged: (value) => courseYear = value,
                ),
                const SizedBox(height: 15),

                // Paper Year Field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: "Paper Year",
                    filled: true,
                    fillColor: Colors.blueGrey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) => value!.isEmpty ? "Required" : null,
                  onChanged: (value) => paperYear = value,
                ),
                const SizedBox(height: 20),

                // Select PDF Button
                ElevatedButton(
                  onPressed: pickPDF,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey, // Button color
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Text(
                      "Select PDF",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Display selected PDF path
                selectedPDF != null
                    ? Text("Selected: ${selectedPDF!.path}")
                    : const Text("No file selected"),
                const SizedBox(height: 20),

                // Upload Button with loading indicator
                ElevatedButton(
                  onPressed: isUploading ? null : uploadPDF,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey, // Success button color
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: isUploading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Text(
                            "Upload PDF",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
