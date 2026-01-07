import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsNotifier extends ChangeNotifier {
  final User? user = FirebaseAuth.instance.currentUser;
  
  // Theme settings
  bool _isDarkMode = false;
  
  // Notification settings
  bool _enableNotifications = true;
  bool _enableEmailNotifications = true;
  bool _enablePushNotifications = true;
  bool _soundEnabled = true;
  
  // Privacy settings
  bool _makeProfilePublic = false;
  bool _allowDataCollection = true;
  
  // Getters
  bool get isDarkMode => _isDarkMode;
  bool get enableNotifications => _enableNotifications;
  bool get enableEmailNotifications => _enableEmailNotifications;
  bool get emailNotifications => _enableEmailNotifications;
  bool get pushNotifications => _enablePushNotifications;
  bool get soundEnabled => _soundEnabled;
  bool get makeProfilePublic => _makeProfilePublic;
  bool get allowDataCollection => _allowDataCollection;
  
  // Initialize settings from SharedPreferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      _enableNotifications = prefs.getBool('enableNotifications') ?? true;
      _enableEmailNotifications = prefs.getBool('enableEmailNotifications') ?? true;
      _enablePushNotifications = prefs.getBool('enablePushNotifications') ?? true;
      _soundEnabled = prefs.getBool('soundEnabled') ?? true;
      _makeProfilePublic = prefs.getBool('makeProfilePublic') ?? false;
      _allowDataCollection = prefs.getBool('allowDataCollection') ?? true;
      
      notifyListeners();
    } catch (e) {
      print('Error loading settings: $e');
    }
  }
  
  // Save all settings
  Future<void> saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save to SharedPreferences
      await prefs.setBool('darkMode', _isDarkMode);
      await prefs.setBool('enableNotifications', _enableNotifications);
      await prefs.setBool('enableEmailNotifications', _enableEmailNotifications);
      await prefs.setBool('enablePushNotifications', _enablePushNotifications);
      await prefs.setBool('soundEnabled', _soundEnabled);
      await prefs.setBool('makeProfilePublic', _makeProfilePublic);
      await prefs.setBool('allowDataCollection', _allowDataCollection);
      
      // Also save some settings to Firestore for cross-device sync
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({
          'settings': {
            'enableEmailNotifications': _enableEmailNotifications,
            'makeProfilePublic': _makeProfilePublic,
            'allowDataCollection': _allowDataCollection,
            'updatedAt': FieldValue.serverTimestamp(),
          }
        });
      }
      
      notifyListeners();
    } catch (e) {
      print('Error saving settings: $e');
      rethrow;
    }
  }
  
  // Individual setters
  void setDarkMode(bool value) {
    if (_isDarkMode != value) {
      _isDarkMode = value;
      notifyListeners();
    }
  }
  
  
  void setEnableNotifications(bool value) {
    if (_enableNotifications != value) {
      _enableNotifications = value;
      notifyListeners();
    }
  }
  
  void setEnableEmailNotifications(bool value) {
    if (_enableEmailNotifications != value) {
      _enableEmailNotifications = value;
      notifyListeners();
    }
  }
  
  Future<void> setEmailNotifications(bool value) async {
    if (_enableEmailNotifications != value) {
      _enableEmailNotifications = value;
      await saveSettings();
    }
  }
  
  Future<void> setPushNotifications(bool value) async {
    if (_enablePushNotifications != value) {
      _enablePushNotifications = value;
      await saveSettings();
    }
  }
  
  Future<void> setSoundEnabled(bool value) async {
    if (_soundEnabled != value) {
      _soundEnabled = value;
      await saveSettings();
    }
  }
  
  void setMakeProfilePublic(bool value) {
    if (_makeProfilePublic != value) {
      _makeProfilePublic = value;
      notifyListeners();
    }
  }
  
  void setAllowDataCollection(bool value) {
    if (_allowDataCollection != value) {
      _allowDataCollection = value;
      notifyListeners();
    }
  }
}
