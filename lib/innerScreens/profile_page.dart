import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late String userId;

  Map<String, dynamic> _userData = {
    'name': '',
    'roll_number': '',
    'phone': '',
    'department': '',
    'role': '',
    'email': '',
    'subject': '',
  };

  bool _isLoading = false;
  bool _isEditing = false;
  bool _isChangingPassword = false;

  final _formKey = GlobalKey<FormState>();
  final _passwordFormKey = GlobalKey<FormState>();

  String _currentPassword = '';
  String _newPassword = '';

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  Future<void> _fetchUserDetails() async {
    setState(() => _isLoading = true);
    userId = _auth.currentUser!.uid;

    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        setState(() {
          _userData = {
            'name': doc['name'] ?? '',
            'roll_number': doc['roll_number'] ?? '',
            'phone': doc['phone'] ?? '',
            'department': doc['department'] ?? '',
            'role': doc['role'] ?? '',
            'email': doc['email'] ?? '',
            'subject': doc['subject'] ?? '',
          };
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to fetch user details: $e")));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateUserDetails() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _firestore.collection('users').doc(userId).update({
          'name': _userData['name'],
          'roll_number': _userData['roll_number'],
          'phone': _userData['phone'],
          'department': _userData['department'],
          'subject': _userData['subject'],
        });

        setState(() => _isEditing = false);

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Profile updated successfully")));
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to update profile")));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updatePassword() async {
    if (_passwordFormKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        AuthCredential credential = EmailAuthProvider.credential(
          email: _auth.currentUser!.email!,
          password: _currentPassword,
        );

        await _auth.currentUser!.reauthenticateWithCredential(credential);
        await _auth.currentUser!.updatePassword(_newPassword);

        setState(() {
          _isChangingPassword = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Password updated successfully")));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to update password: $e")));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Colors.blueGrey,
        // centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildTextField(
                              label: 'Name',
                              field: 'name',
                              isEditable: _isEditing),
                          _buildTextField(
                              label: 'Roll Number',
                              field: 'roll_number',
                              isEditable:
                                  _userData['role'] == 'Student' && _isEditing),
                          _buildTextField(
                              label: 'Phone',
                              field: 'phone',
                              isEditable: _isEditing),
                          _buildTextField(
                              label: 'Department',
                              field: 'department',
                              isEditable: _isEditing),
                          _buildTextField(
                              label: 'Role', field: 'role', isEditable: false),
                          _buildTextField(
                              label: 'Email',
                              field: 'email',
                              isEditable: false),
                          _buildTextField(
                              label: 'Subject',
                              field: 'subject',
                              isEditable:
                                  _userData['role'] == 'Teacher' && _isEditing),
                          const SizedBox(height: 20),
                          _isEditing
                              ? ElevatedButton(
                                  onPressed: _updateUserDetails,
                                  child: const Text(
                                    "Save Changes",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueGrey),
                                )
                              : ElevatedButton(
                                  onPressed: () =>
                                      setState(() => _isEditing = true),
                                  child: const Text(
                                    "Edit Profile",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueGrey),
                                ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () =>
                                setState(() => _isChangingPassword = true),
                            child: const Text(
                              "Change Password",
                              style: TextStyle(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                    if (_isChangingPassword) _buildPasswordForm(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTextField(
      {required String label,
      required String field,
      required bool isEditable}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: _userData[field],
        decoration:
            InputDecoration(labelText: label, border: OutlineInputBorder()),
        enabled: isEditable,
        onChanged: (value) => _userData[field] = value,
        validator: (value) => value == null ||
                value.isEmpty && label != 'Roll Number' && label != 'subject'
            ? '$label is required'
            : null,
      ),
    );
  }

  Widget _buildPasswordForm() {
    return Form(
      key: _passwordFormKey,
      child: Column(
        children: [
          _buildPasswordField(
              "Current Password", (value) => _currentPassword = value),
          _buildPasswordField("New Password", (value) => _newPassword = value),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _updatePassword,
            child: const Text("Update Password"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(String label, Function(String) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        decoration:
            InputDecoration(labelText: label, border: OutlineInputBorder()),
        obscureText: true,
        onChanged: onChanged,
        validator: (value) =>
            value == null || value.isEmpty ? '$label is required' : null,
      ),
    );
  }
}
