import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class UploadNotesPage extends StatefulWidget {
  const UploadNotesPage({super.key});

  @override
  _UploadNotesPageState createState() => _UploadNotesPageState();
}

class _UploadNotesPageState extends State<UploadNotesPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectNameController = TextEditingController();
  final TextEditingController _subjectCodeController = TextEditingController();
  final TextEditingController _courseYearController = TextEditingController();

  File? _selectedFile;
  bool _isUploading = false;

  /// Picks a PDF file from the device
  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
      });
    }
  }

  /// Uploads the file to Cloudinary and returns the file URL
  Future<String?> _uploadToCloudinary(File file) async {
    String cloudName = dotenv.env['CLOUD_NAME']!;
    String cloudinaryUrl =
        "https://api.cloudinary.com/v1_1/$cloudName/raw/upload";
    String uploadPreset = dotenv.env['UPLOAD_PRESET']!;

    var request = http.MultipartRequest("POST", Uri.parse(cloudinaryUrl))
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseBody = await response.stream.bytesToString();
      var data = jsonDecode(responseBody);
      return data['secure_url']; // Extract the Cloudinary file URL
    } else {
      return null;
    }
  }

  /// Uploads metadata to Firestore
  Future<void> _uploadNotes() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please select a file")));
      return;
    }

    setState(() {
      _isUploading = true;
    });

    String? fileUrl = await _uploadToCloudinary(_selectedFile!);
    if (fileUrl == null) {
      setState(() {
        _isUploading = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("File upload failed")));
      return;
    }
    User? user = FirebaseAuth.instance.currentUser;
    String userId = user?.uid ?? "null";
    DocumentSnapshot userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    String uploaderName = userDoc.exists ? userDoc['name'] : "Unknown User";

    await FirebaseFirestore.instance.collection('notes_files').add({
      'subject_name': _subjectNameController.text,
      'subject_code': _subjectCodeController.text,
      'course_year': _courseYearController.text,
      'uploader_name': uploaderName,
      'file_url':
          fileUrl, // ✅ Corrected: Now properly storing the Cloudinary URL in Firestore
      'uploaded_at': Timestamp.now(),
    });

    setState(() {
      _isUploading = false;
      _selectedFile = null;
      _subjectNameController.clear();
      _subjectCodeController.clear();
      _courseYearController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Notes uploaded successfully")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Upload Notes",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.blueGrey, // Blue-grey theme
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject Name input field
                TextFormField(
                  controller: _subjectNameController,
                  decoration: InputDecoration(
                    labelText: "Subject Name",
                    labelStyle: TextStyle(color: Colors.blueGrey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.blueGrey.shade50,
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Enter subject name" : null,
                ),
                const SizedBox(height: 16), // Spacing between fields

                // Subject Code input field
                TextFormField(
                  controller: _subjectCodeController,
                  decoration: InputDecoration(
                    labelText: "Subject Code",
                    labelStyle: TextStyle(color: Colors.blueGrey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.blueGrey.shade50,
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Enter subject code" : null,
                ),
                const SizedBox(height: 16), // Spacing between fields

                // Course Year input field
                TextFormField(
                  controller: _courseYearController,
                  decoration: InputDecoration(
                    labelText: "Course Year",
                    labelStyle: TextStyle(color: Colors.blueGrey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.blueGrey.shade50,
                  ),
                  validator: (value) =>
                      value!.isEmpty ? "Enter course year" : null,
                ),
                const SizedBox(height: 16), // Spacing between fields

                // Button to select a file
                ElevatedButton(
                  onPressed: _pickFile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueGrey,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Text(
                      "Select PDF File",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 16), // Space between buttons

                // Display selected file name
                if (_selectedFile != null)
                  Text(
                    "Selected File: ${path.basename(_selectedFile!.path)}",
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                const SizedBox(height: 16), // Spacing

                // Upload button with loading indicator
                _isUploading
                    ? Center(child: const CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _uploadNotes,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Text(
                            "Upload Notes",
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
