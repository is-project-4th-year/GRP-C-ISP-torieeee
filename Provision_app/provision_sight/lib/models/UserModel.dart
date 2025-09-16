// models/user_model.dart
class User {
  String firstName;
  String lastName;
  String phone;
  String email;
  EmergencyContact emergencyContact;
  List<String> voiceSamples;

  User({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.emergencyContact,
    required this.voiceSamples,
  });

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'emergencyContact': emergencyContact.toMap(),
      'voiceSamples': voiceSamples,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  static User fromMap(Map<String, dynamic> map) {
    return User(
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      emergencyContact: EmergencyContact.fromMap(
        map['emergencyContact'] is Map 
          ? Map<String, dynamic>.from(map['emergencyContact']) 
          : {},
      ),
      voiceSamples: List<String>.from(map['voiceSamples'] ?? []),
    );
  }
}

class EmergencyContact {
  String name;
  String phone;
  String email;
  String relationship;

  EmergencyContact({
    required this.name,
    required this.phone,
    required this.email,
    required this.relationship,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'relationship': relationship,
    };
  }

  static EmergencyContact fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      relationship: map['relationship'] ?? '',
    );
  }
}