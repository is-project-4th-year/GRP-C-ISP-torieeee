// utils/app_storage.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/UserModel.dart';

class AppStorage {
  static late SharedPreferences _prefs;
  static final String _userKey = 'provision_user_data';
  static final String _voiceSamplesKey = 'provision_voice_samples';
  static final String _appModeKey = 'provision_app_mode';
  static final String _isLoggedInKey = 'provision_is_logged_in';

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }
  // Add these to AppStorage.dart

static final String _fingerprintEnrolledKey = 'provision_fingerprint_enrolled';

static Future<void> saveFingerprintEnrolled(bool enrolled) async {
  await _prefs.setBool(_fingerprintEnrolledKey, enrolled);
}

static bool isFingerprintEnrolled() {
  return _prefs.getBool(_fingerprintEnrolledKey) ?? false;
}

  // User data methods
  static Future<void> saveUser(User user) async {
    final userData = user.toMap();
    await _prefs.setString(_userKey, json.encode(userData));
  }

  static User? getUser() {
    final userDataString = _prefs.getString(_userKey);
    if (userDataString != null) {
      try {
        final userData = json.decode(userDataString) as Map<String, dynamic>;
        return User.fromMap(userData);
      } catch (e) {
        print('Error parsing user data: $e');
        return null;
      }
    }
    return null;
  }

  static Future<void> deleteUser() async {
    await _prefs.remove(_userKey);
    await _prefs.remove(_voiceSamplesKey);
    await _prefs.setBool(_isLoggedInKey, false);
  }

  // Voice samples methods
  static Future<void> saveVoiceSamples(List<String> samplePaths) async {
    await _prefs.setStringList(_voiceSamplesKey, samplePaths);
  }

  static List<String> getVoiceSamples() {
    return _prefs.getStringList(_voiceSamplesKey) ?? [];
  }

  // App mode methods (online/offline)
  static Future<void> saveAppMode(bool isOnline) async {
    await _prefs.setBool(_appModeKey, isOnline);
  }

  static bool getAppMode() {
    return _prefs.getBool(_appModeKey) ?? true; // Default to online mode
  }

  // Login status methods
  static Future<void> setLoggedIn(bool isLoggedIn) async {
    await _prefs.setBool(_isLoggedInKey, isLoggedIn);
  }

  static bool isLoggedIn() {
    return _prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Emergency contact methods
  static Future<void> saveEmergencyContact(EmergencyContact contact) async {
    final user = getUser();
    if (user != null) {
      user.emergencyContact = contact;
      await saveUser(user);
    }
  }

  static EmergencyContact? getEmergencyContact() {
    final user = getUser();
    return user?.emergencyContact;
  }

  // Clear all data (for logout)
  static Future<void> clearAllData() async {
    await _prefs.clear();
  }

  // Check if user has completed registration
  static bool hasCompletedRegistration() {
    final user = getUser();
    final voiceSamples = getVoiceSamples();
    return user != null && voiceSamples.isNotEmpty;
  }

  // Backup and restore methods
  static Future<String> exportUserData() async {
    final user = getUser();
    final voiceSamples = getVoiceSamples();
    final appMode = getAppMode();
    
    final data = {
      'user': user?.toMap(),
      'voiceSamples': voiceSamples,
      'appMode': appMode,
      'exportDate': DateTime.now().toIso8601String(),
    };
    
    return json.encode(data);
  }

  static Future<bool> importUserData(String jsonData) async {
    try {
      final data = json.decode(jsonData) as Map<String, dynamic>;
      
      if (data['user'] != null) {
        final user = User.fromMap(data['user'] as Map<String, dynamic>);
        await saveUser(user);
      }
      
      if (data['voiceSamples'] != null) {
        final samples = List<String>.from(data['voiceSamples'] as List);
        await saveVoiceSamples(samples);
      }
      
      if (data['appMode'] != null) {
        await saveAppMode(data['appMode'] as bool);
      }
      
      return true;
    } catch (e) {
      print('Error importing user data: $e');
      return false;
    }
  }

  // Migration methods for future updates
  static Future<void> migrateData() async {
    // Check if we need to migrate from old format to new format
    final oldUserKey = 'provision_user';
    final oldUserData = _prefs.getString(oldUserKey);
    
    if (oldUserData != null) {
      try {
        // Migrate from old format to new format
        final oldData = json.decode(oldUserData) as Map<String, dynamic>;
        // Add migration logic here if needed
        
        // Remove old key after migration
        await _prefs.remove(oldUserKey);
      } catch (e) {
        print('Error during data migration: $e');
      }
    }
  }
}