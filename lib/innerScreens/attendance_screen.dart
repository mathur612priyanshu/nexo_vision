import 'dart:io';
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

class MarkAttendanceScreen extends StatefulWidget {
  const MarkAttendanceScreen({super.key});

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<MarkAttendanceScreen> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  File? _capturedImage;

  final String apiKey = dotenv.env['FACE_API_KEY']!;
  final String apiSecret = dotenv.env['FACE_API_SECRET']!;
  final String outerId = dotenv.env['FACE_OUTER_ID']!; // FaceSet ID

  @override
  void initState() {
    super.initState();
    _initializeCamera(); // Initialize camera when the screen is loaded
  }

  // Initialize the camera and set up the controller
  Future<void> _initializeCamera() async {
    _cameras = await availableCameras(); // Get available cameras
    _cameraController = CameraController(
      _cameras![0], // Use the back camera (index 0)
      ResolutionPreset.medium,
      enableAudio: false, // Disable audio for video capture
    );

    await _cameraController!.initialize(); // Initialize the camera

    if (mounted) {
      setState(
          () => _isCameraInitialized = true); // Update the UI once initialized
    }
  }

  // Capture an image from the camera
  Future<void> _captureImage() async {
    if (!_isCameraInitialized || _isProcessing)
      return; // Don't capture if camera is not ready or it's already processing

    setState(() => _isProcessing = true); // Show loading state
    XFile imageFile =
        await _cameraController!.takePicture(); // Take picture from the camera
    File file = File(imageFile.path);

    setState(() {
      _capturedImage = file; // Set the captured image
      _isProcessing = false; // Hide loading state
    });

    _verifyFace(file); // Call the face recognition function
  }

  // Verify the captured face using Face++ API
  Future<void> _verifyFace(File imageFile) async {
    String imagePath = imageFile.path;

    try {
      var request = http.MultipartRequest('POST',
          Uri.parse("https://api-us.faceplusplus.com/facepp/v3/search"));
      request.fields['api_key'] = apiKey;
      request.fields['api_secret'] = apiSecret;
      request.fields['outer_id'] = outerId;
      request.files
          .add(await http.MultipartFile.fromPath('image_file', imagePath));

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(responseData);
        var candidates = jsonResponse['results'];

        // If face recognition confidence is above threshold, mark attendance
        if (candidates != null && candidates.isNotEmpty) {
          double confidence = candidates[0]['confidence'];
          String matchedFaceToken = candidates[0]['face_token'];

          if (confidence > 75) {
            _fetchStudentDetails(
                matchedFaceToken); // Fetch student details if match is found
          } else {
            _showMessage("Face not recognized. Try again!");
          }
        } else {
          _showMessage("No matching faces found!");
        }
      } else {
        _showMessage("Error in face recognition.");
      }
    } catch (e) {
      _showMessage("Failed: $e");
    }
  }

  // Fetch student details from Firestore based on the matched face token
  Future<void> _fetchStudentDetails(String faceToken) async {
    try {
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('users')
          .where('face_token', isEqualTo: faceToken)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        var userDoc = query.docs.first;
        String userId = userDoc.id;
        String studentName = userDoc['name'];
        String rollNumber = userDoc['roll_number'];

        await _markAttendance(
            userId, studentName, rollNumber); // Mark attendance
      } else {
        _showMessage("User not found in database.");
      }
    } catch (e) {
      _showMessage("Error fetching user details: $e");
    }
  }

  // Mark attendance in Firestore
  Future<void> _markAttendance(
      String userId, String name, String rollNumber) async {
    try {
      // Get the current date in yyyy-MM-dd format
      String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

      await FirebaseFirestore.instance.collection('attendance').add({
        'user_id': userId,
        'name': name,
        'roll_number': rollNumber,
        'date': formattedDate, // Save the formatted date
      });

      _showMessage("Attendance marked for: $name ✅");
    } catch (e) {
      _showMessage("Error marking attendance: $e");
    }
  }

  // Display a message on the screen
  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _cameraController
        ?.dispose(); // Dispose of the camera controller when the screen is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text(
          "Mark Attendance",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blueGrey, // Custom color for app bar
      ),
      body: Column(
        children: [
          // Camera preview with aspect ratio to prevent stretching
          _isCameraInitialized
              ? AspectRatio(
                  aspectRatio: _cameraController!
                      .value.aspectRatio, // Aspect ratio based on camera
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationZ(
                        90 * 3.1415927 / 180), // Rotate preview by -90 degrees
                    child: CameraPreview(_cameraController!),
                  ),
                )
              : const Center(child: CircularProgressIndicator()),

          Flexible(child: const SizedBox(height: 90)),

          // Button to capture image
          ElevatedButton(
            onPressed: _captureImage,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey, // Button color
              padding: const EdgeInsets.symmetric(vertical: 15),
              textStyle: const TextStyle(fontSize: 18),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Mark Attendance",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
