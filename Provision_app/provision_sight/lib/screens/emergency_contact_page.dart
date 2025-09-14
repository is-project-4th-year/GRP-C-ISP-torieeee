// screens/emergency_contact_page.dart
import 'package:flutter/material.dart';

class EmergencyContactPage extends StatefulWidget {
  @override
  _EmergencyContactPageState createState() => _EmergencyContactPageState();
}

class _EmergencyContactPageState extends State<EmergencyContactPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load emergency contact data (in a real app, this would come from a database)
    _loadEmergencyContactData();
  }

  void _loadEmergencyContactData() {
    // Placeholder for loading emergency contact data
    _nameController.text = "Jane Smith";
    _phoneController.text = "+1 987-654-3210";
    _emailController.text = "jane.smith@example.com";
    _relationshipController.text = "Spouse";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Emergency Contact'),
        backgroundColor: Color(0xFF1B5E20),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveEmergencyContact,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: ListView(
          children: [
            _buildEditableField(
              controller: _nameController,
              label: 'Contact Name',
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
            SizedBox(height: 16),
            _buildEditableField(
              controller: _relationshipController,
              label: 'Relationship',
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _testEmergencyCall,
              child: Text('Test Emergency Call'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: _saveEmergencyContact,
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

  void _saveEmergencyContact() {
    // Save emergency contact logic would go here
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Emergency contact saved successfully!')),
    );
  }

  void _testEmergencyCall() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Test Emergency Call'),
        content: Text('Would you like to test call ${_nameController.text} at ${_phoneController.text}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Test call placed successfully!')),
              );
            },
            child: Text('Call'),
          ),
        ],
      ),
    );
  }
}