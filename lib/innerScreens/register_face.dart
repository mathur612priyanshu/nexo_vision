import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterFaceScreen extends StatefulWidget {
  const RegisterFaceScreen({super.key});

  @override
  _RegisterFaceScreenState createState() => _RegisterFaceScreenState();
}

class _RegisterFaceScreenState extends State<RegisterFaceScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  File? _capturedImage;

  // Face++ API Credentials
  final String apiKey = dotenv.env['FACE_API_KEY']!;
  final String apiSecret = dotenv.env['FACE_API_SECRET']!;
  final String outerId = dotenv.env['FACE_OUTER_ID']!; // FaceSet ID

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  /// Initializes the front camera with a fixed aspect ratio (4:3)
  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(
      _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front),
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();

    if (mounted) {
      setState(() => _isCameraInitialized = true);
    }
  }

  /// Captures an image and registers the face
  Future<void> _captureImage() async {
    if (!_isCameraInitialized || _isProcessing) return;

    setState(() => _isProcessing = true);
    XFile imageFile = await _cameraController!.takePicture();
    File file = File(imageFile.path);

    setState(() {
      _capturedImage = file;
      _isProcessing = false;
    });

    _registerFace(file);
  }

  /// Registers the captured face using Face++ API
  Future<void> _registerFace(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("https://api-us.faceplusplus.com/facepp/v3/detect"),
      );
      request.fields['api_key'] = apiKey;
      request.fields['api_secret'] = apiSecret;
      request.files
          .add(await http.MultipartFile.fromPath('image_file', imageFile.path));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(responseData);
        if (jsonResponse['faces'].isNotEmpty) {
          String faceToken = jsonResponse['faces'][0]['face_token'];
          _addFaceToFaceSet(faceToken);
        } else {
          _showMessage("No face detected. Try again.");
        }
      } else {
        _showMessage("Error detecting face.");
      }
    } catch (e) {
      _showMessage("Error: $e");
    }
  }

  /// Adds the face token to the FaceSet
  Future<void> _addFaceToFaceSet(String faceToken) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse("https://api-us.faceplusplus.com/facepp/v3/faceset/addface"),
      );
      request.fields['api_key'] = apiKey;
      request.fields['api_secret'] = apiSecret;
      request.fields['outer_id'] = outerId;
      request.fields['face_tokens'] = faceToken;

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        _saveUserToFirestore(faceToken);
      } else {
        _showMessage("Failed to add face to FaceSet.");
      }
    } catch (e) {
      _showMessage("Error: $e");
    }
  }

  /// Saves the face token to Firestore
  Future<void> _saveUserToFirestore(String faceToken) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      String name = userDoc.exists ? userDoc['name'] : "Unknown User";

      // Update Firestore document without overwriting existing data
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'face_token': faceToken,
      }, SetOptions(merge: true));

      _showMessage("$name, your face has been registered successfully!");
    } catch (e) {
      _showMessage("Error saving user data: $e");
    }
  }

  /// Displays a message using SnackBar
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50], // Light themed background
      appBar: AppBar(
        title: const Text(
          "Register Face",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.blueGrey,
        elevation: 2,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            _isCameraInitialized
                ? AspectRatio(
                    aspectRatio: 4 / 3, // Correct aspect ratio for front camera
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(15), // Rounded corners
                      child: Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.rotationZ(-90 *
                            3.1415927 /
                            180), // Rotate preview by -90 degrees
                        child: CameraPreview(_cameraController!),
                      ),
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 10),
            if (_capturedImage != null)
              Column(
                children: [
                  const Text("Captured Image:",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(_capturedImage!,
                        width: 200, height: 200, fit: BoxFit.cover),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _captureImage,
              icon: const Icon(
                Icons.camera_alt,
                color: Colors.white,
              ),
              label: const Text(
                "Capture Face",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Ensure proper lighting & face visibility before capturing.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.blueGrey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
