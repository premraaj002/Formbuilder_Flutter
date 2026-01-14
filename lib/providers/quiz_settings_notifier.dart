import 'package:flutter/foundation.dart';
import '../models/quiz_settings_model.dart';

/// Provider for managing quiz settings state
/// Extends ChangeNotifier to notify listeners of setting changes
class QuizSettingsNotifier extends ChangeNotifier {
  QuizSettingsModel _settings = QuizSettingsModel.defaults();

  QuizSettingsModel get settings => _settings;

  /// Load settings from a model (e.g., when loading an existing quiz)
  void loadSettings(QuizSettingsModel settings) {
    _settings = settings;
    notifyListeners();
  }

  /// Reset to default settings
  void resetToDefaults() {
    _settings = QuizSettingsModel.defaults();
    notifyListeners();
  }

  /// Update timer limit in minutes
  void setTimeLimitMinutes(int? minutes) {
    _settings = _settings.copyWith(
      timeLimitMinutes: minutes,
      clearTimeLimitMinutes: minutes == null,
    );
    notifyListeners();
  }

  /// Toggle auto-submit when timer expires
  void setAutoSubmit(bool value) {
    _settings = _settings.copyWith(autoSubmit: value);
    notifyListeners();
  }

  /// Toggle tab switch restriction
  void setEnableTabRestriction(bool value) {
    _settings = _settings.copyWith(enableTabRestriction: value);
    notifyListeners();
  }

  /// Update maximum allowed tab switches
  void setMaxTabSwitchCount(int? count) {
    _settings = _settings.copyWith(
      maxTabSwitchCount: count,
      clearMaxTabSwitchCount: count == null,
    );
    notifyListeners();
  }

  /// Toggle negative marking
  void setNegativeMarking(bool value) {
    _settings = _settings.copyWith(negativeMarking: value);
    notifyListeners();
  }

  /// Update negative marking points
  void setNegativeMarkingPoints(int points) {
    _settings = _settings.copyWith(negativeMarkingPoints: points);
    notifyListeners();
  }

  /// Toggle show score at end
  void setShowScoreAtEnd(bool value) {
    _settings = _settings.copyWith(showScoreAtEnd: value);
    notifyListeners();
  }

  /// Toggle shuffle questions
  void setShuffleQuestions(bool value) {
    _settings = _settings.copyWith(shuffleQuestions: value);
    notifyListeners();
  }

  /// Toggle shuffle options within questions
  void setShuffleOptions(bool value) {
    _settings = _settings.copyWith(shuffleOptions: value);
    notifyListeners();
  }

  /// Toggle allow back navigation
  void setAllowBackNavigation(bool value) {
    _settings = _settings.copyWith(allowBackNavigation: value);
    notifyListeners();
  }

  /// Toggle allow retake
  void setAllowRetake(bool value) {
    _settings = _settings.copyWith(allowRetake: value);
    notifyListeners();
  }

  /// Validate current settings and return list of errors
  List<String> validate() {
    return _settings.validate();
  }

  /// Check if current settings are valid
  bool get isValid => _settings.isValid;

  /// Get settings as JSON for storage
  Map<String, dynamic> toJson() {
    return _settings.toJson();
  }
}
