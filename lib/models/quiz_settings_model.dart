import 'package:flutter/foundation.dart';

/// Model class for Quiz Settings
/// Centralizes all quiz configuration including timer, restrictions, scoring, and display options
class QuizSettingsModel {
  // Timer Settings
  final int? timeLimitMinutes;
  final bool autoSubmit;
  
  // Tab Switch Restriction Settings (Web only)
  final bool enableTabRestriction;
  final int? maxTabSwitchCount;
  
  // Scoring Settings
  final bool negativeMarking;
  final int negativeMarkingPoints;
  final bool showScoreAtEnd;
  
  // Quiz Behavior Settings
  final bool shuffleQuestions;
  final bool shuffleOptions;
  final bool allowBackNavigation;
  final bool allowRetake;
  
  const QuizSettingsModel({
    this.timeLimitMinutes,
    this.autoSubmit = true,
    this.enableTabRestriction = false,
    this.maxTabSwitchCount,
    this.negativeMarking = false,
    this.negativeMarkingPoints = 1,
    this.showScoreAtEnd = true,
    this.shuffleQuestions = false,
    this.shuffleOptions = false,
    this.allowBackNavigation = true,
    this.allowRetake = true,
  });

  /// Default settings for a new quiz
  factory QuizSettingsModel.defaults() {
    return const QuizSettingsModel();
  }

  /// Create from JSON with migration support from legacy Map-based settings
  factory QuizSettingsModel.fromJson(Map<String, dynamic> json) {
    try {
      return QuizSettingsModel(
        // Timer settings - support legacy fields
        timeLimitMinutes: json['timeLimitMinutes'] ?? 
                         json['timeLimit'], // Legacy field
        autoSubmit: json['autoSubmit'] ?? true,
        
        // Tab restriction settings
        enableTabRestriction: json['enableTabRestriction'] ?? false,
        maxTabSwitchCount: json['maxTabSwitchCount'] ?? 
                          json['maxTabSwitches'], // Legacy field
        
        // Scoring settings
        negativeMarking: json['negativeMarking'] ?? false,
        negativeMarkingPoints: json['negativeMarkingPoints'] ?? 1,
        showScoreAtEnd: json['showScoreAtEnd'] ?? true,
        
        // Behavior settings
        shuffleQuestions: json['shuffleQuestions'] ?? false,
        shuffleOptions: json['shuffleOptions'] ?? false,
        allowBackNavigation: json['allowBackNavigation'] ?? true,
        allowRetake: json['allowRetake'] ?? true,
      );
    } catch (e) {
      debugPrint('Error parsing QuizSettingsModel: $e');
      debugPrint('JSON data: $json');
      // Return defaults if parsing fails
      return QuizSettingsModel.defaults();
    }
  }

  /// Convert to JSON for Firestore storage
  Map<String, dynamic> toJson() {
    return {
      'timeLimitMinutes': timeLimitMinutes,
      'autoSubmit': autoSubmit,
      'enableTabRestriction': enableTabRestriction,
      'maxTabSwitchCount': maxTabSwitchCount,
      'negativeMarking': negativeMarking,
      'negativeMarkingPoints': negativeMarkingPoints,
      'showScoreAtEnd': showScoreAtEnd,
      'shuffleQuestions': shuffleQuestions,
      'shuffleOptions': shuffleOptions,
      'allowBackNavigation': allowBackNavigation,
      'allowRetake': allowRetake,
    };
  }

  /// Validate quiz settings and return a list of error messages
  /// Returns empty list if all settings are valid
  List<String> validate() {
    final errors = <String>[];

    // Validate timer settings
    if (timeLimitMinutes != null) {
      if (timeLimitMinutes! <= 0) {
        errors.add('Timer duration must be greater than 0 minutes');
      }
      if (timeLimitMinutes! > 480) {
        errors.add('Timer duration cannot exceed 480 minutes (8 hours)');
      }
    }

    // Validate tab restriction settings
    if (enableTabRestriction) {
      if (maxTabSwitchCount == null) {
        errors.add('Maximum tab switches must be set when tab restriction is enabled');
      } else if (maxTabSwitchCount! <= 0) {
        errors.add('Maximum tab switches must be greater than 0');
      } else if (maxTabSwitchCount! > 100) {
        errors.add('Maximum tab switches cannot exceed 100');
      }
    }

    // Validate negative marking settings
    if (negativeMarking) {
      if (negativeMarkingPoints < 0) {
        errors.add('Negative marking points cannot be negative');
      }
      if (negativeMarkingPoints > 10) {
        errors.add('Negative marking points cannot exceed 10');
      }
    }

    return errors;
  }

  /// Check if settings are valid
  bool get isValid => validate().isEmpty;

  /// Create a copy with updated fields
  QuizSettingsModel copyWith({
    int? timeLimitMinutes,
    bool? clearTimeLimitMinutes, // Special flag to clear timer
    bool? autoSubmit,
    bool? enableTabRestriction,
    int? maxTabSwitchCount,
    bool? clearMaxTabSwitchCount, // Special flag to clear tab count
    bool? negativeMarking,
    int? negativeMarkingPoints,
    bool? showScoreAtEnd,
    bool? shuffleQuestions,
    bool? shuffleOptions,
    bool? allowBackNavigation,
    bool? allowRetake,
  }) {
    return QuizSettingsModel(
      timeLimitMinutes: clearTimeLimitMinutes == true 
          ? null 
          : timeLimitMinutes ?? this.timeLimitMinutes,
      autoSubmit: autoSubmit ?? this.autoSubmit,
      enableTabRestriction: enableTabRestriction ?? this.enableTabRestriction,
      maxTabSwitchCount: clearMaxTabSwitchCount == true 
          ? null 
          : maxTabSwitchCount ?? this.maxTabSwitchCount,
      negativeMarking: negativeMarking ?? this.negativeMarking,
      negativeMarkingPoints: negativeMarkingPoints ?? this.negativeMarkingPoints,
      showScoreAtEnd: showScoreAtEnd ?? this.showScoreAtEnd,
      shuffleQuestions: shuffleQuestions ?? this.shuffleQuestions,
      shuffleOptions: shuffleOptions ?? this.shuffleOptions,
      allowBackNavigation: allowBackNavigation ?? this.allowBackNavigation,
      allowRetake: allowRetake ?? this.allowRetake,
    );
  }

  @override
  String toString() {
    return 'QuizSettingsModel('
        'timeLimitMinutes: $timeLimitMinutes, '
        'autoSubmit: $autoSubmit, '
        'enableTabRestriction: $enableTabRestriction, '
        'maxTabSwitchCount: $maxTabSwitchCount, '
        'negativeMarking: $negativeMarking, '
        'negativeMarkingPoints: $negativeMarkingPoints, '
        'showScoreAtEnd: $showScoreAtEnd, '
        'shuffleQuestions: $shuffleQuestions, '
        'shuffleOptions: $shuffleOptions, '
        'allowBackNavigation: $allowBackNavigation, '
        'allowRetake: $allowRetake'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuizSettingsModel &&
        other.timeLimitMinutes == timeLimitMinutes &&
        other.autoSubmit == autoSubmit &&
        other.enableTabRestriction == enableTabRestriction &&
        other.maxTabSwitchCount == maxTabSwitchCount &&
        other.negativeMarking == negativeMarking &&
        other.negativeMarkingPoints == negativeMarkingPoints &&
        other.showScoreAtEnd == showScoreAtEnd &&
        other.shuffleQuestions == shuffleQuestions &&
        other.shuffleOptions == shuffleOptions &&
        other.allowBackNavigation == allowBackNavigation &&
        other.allowRetake == allowRetake;
  }

  @override
  int get hashCode {
    return Object.hash(
      timeLimitMinutes,
      autoSubmit,
      enableTabRestriction,
      maxTabSwitchCount,
      negativeMarking,
      negativeMarkingPoints,
      showScoreAtEnd,
      shuffleQuestions,
      shuffleOptions,
      allowBackNavigation,
      allowRetake,
    );
  }
}
