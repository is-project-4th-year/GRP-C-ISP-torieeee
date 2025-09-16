// screens/profile_page.dart
import 'package:flutter/material.dart';
import 'package:provision_sight/utils/app_storage.dart';
import 'package:provision_sight/models/UserModel.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    final user = AppStorage.getUser();
    if (user != null) {
      setState(() {
        _firstNameController.text = user.firstName;
        _lastNameController.text = user.lastName;
        _phoneController.text = user.phone;
        _emailController.text = user.email;
        _isLoading = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No user data found. Please sign up first.')),
      );
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Information'),
        backgroundColor: Color(0xFF1B5E20),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16),
              child: ListView(
                children: [
                  _buildEditableField(
                    controller: _firstNameController,
                    label: 'First Name',
                  ),
                  SizedBox(height: 16),
                  _buildEditableField(
                    controller: _lastNameController,
                    label: 'Last Name',
                  ),
                  SizedBox(height: 16),
                  _buildEditableField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 16),
                  _buildEditableField(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _saveProfile,
                    child: Text('Save Changes'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF1B5E20),
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildEditableField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.green),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.greenAccent),
        ),
      ),
    );
  }

  void _saveProfile() async {
    final user = AppStorage.getUser();
    if (user != null) {
      // Update user object
      user.firstName = _firstNameController.text;
      user.lastName = _lastNameController.text;
      user.phone = _phoneController.text;
      user.email = _emailController.text;

      // Save back to storage
      await AppStorage.saveUser(user);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile saved successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No user found. Cannot save profile.')),
      );
    }
  }
}