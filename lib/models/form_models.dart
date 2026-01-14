import 'package:flutter/material.dart';
import 'quiz_settings_model.dart';

class FormQuestion {
  final String id;
  final String type;
  final String title;
  final String? description;
  final bool required;
  final List<String>? options;
  final Map<String, dynamic>? settings;
  final int order;
  // Add quiz-specific fields
  final bool isQuizQuestion;
  final String? correctAnswer;
  final List<String>? correctAnswers;
  final int? points;

  FormQuestion({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    this.required = false,
    this.options,
    this.settings,
    required this.order,
    this.isQuizQuestion = false,
    this.correctAnswer,
    this.correctAnswers,
    this.points = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'required': required,
      'options': options,
      'settings': settings,
      'order': order,
      'isQuizQuestion': isQuizQuestion,
      'correctAnswer': correctAnswer,
      'correctAnswers': correctAnswers,
      'points': points,
    };
  }

  factory FormQuestion.fromJson(Map<String, dynamic> json) {
    try {
      return FormQuestion(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? 'short_answer',
        title: json['title']?.toString() ?? 'Untitled Question',
        description: json['description']?.toString(),
        required: json['required'] ?? false,
        options: json['options'] != null 
            ? List<String>.from(json['options'])
            : null,
        settings: json['settings'] is Map<String, dynamic> 
            ? Map<String, dynamic>.from(json['settings'])
            : null,
        order: json['order'] ?? 0,
        isQuizQuestion: json['isQuizQuestion'] ?? false,
        correctAnswer: json['correctAnswer']?.toString(),
        correctAnswers: json['correctAnswers'] != null 
            ? List<String>.from(json['correctAnswers'])
            : null,
        points: json['points'] ?? 1,
      );
    } catch (e) {
      print('Error parsing FormQuestion: $e');
      print('JSON data: $json');
      // Return a default question if parsing fails
      return FormQuestion(
        id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'short_answer',
        title: 'Error loading question',
        order: 0,
      );
    }
  }

  FormQuestion copyWith({
    String? id,
    String? type,
    String? title,
    String? description,
    bool? required,
    List<String>? options,
    Map<String, dynamic>? settings,
    int? order,
    bool? isQuizQuestion,
    String? correctAnswer,
    List<String>? correctAnswers,
    int? points,
  }) {
    return FormQuestion(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      required: required ?? this.required,
      options: options ?? this.options,
      settings: settings ?? this.settings,
      order: order ?? this.order,
      isQuizQuestion: isQuizQuestion ?? this.isQuizQuestion,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      points: points ?? this.points,
    );
  }
}

class FormData {
  final String? id;
  final String title;
  final String? description;
  final List<FormQuestion> questions;
  final QuizSettingsModel? quizSettings; // Replaced Map<String, dynamic> settings
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublished;
  final bool isDeleted;
  final DateTime? deletedAt;
  final bool isQuiz;

  FormData({
    this.id,
    required this.title,
    this.description,
    required this.questions,
    this.quizSettings, // Use QuizSettingsModel instead of Map
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isPublished = false,
    this.isDeleted = false,
    this.deletedAt,
    this.isQuiz = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),
      'quizSettings': quizSettings?.toJson(), // Serialize QuizSettingsModel
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPublished': isPublished,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
      'isQuiz': isQuiz,
    };
  }

  factory FormData.fromJson(Map<String, dynamic> json) {
    // Handle migration from old Map-based settings to QuizSettingsModel
    QuizSettingsModel? parseQuizSettings() {
      // If not a quiz, no settings needed
      if (json['isQuiz'] != true) return null;
      
      // Try to parse from new format (quizSettings object)
      if (json['quizSettings'] != null && json['quizSettings'] is Map<String, dynamic>) {
        return QuizSettingsModel.fromJson(json['quizSettings']);
      }
      
      // Fallback: migrate from old format (settings Map)
      if (json['settings'] != null && json['settings'] is Map<String, dynamic>) {
        final oldSettings = json['settings'] as Map<String, dynamic>;
        return QuizSettingsModel.fromJson(oldSettings);
      }
      
      // No settings found, return defaults for quizzes
      return QuizSettingsModel.defaults();
    }
    
    return FormData(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      questions: (json['questions'] as List?)
          ?.map((q) => FormQuestion.fromJson(q))
          .toList() ?? [],
      quizSettings: parseQuizSettings(), // Parse quiz settings with migration
      createdBy: json['createdBy'] ?? '',
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      isPublished: json['isPublished'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      deletedAt: json['deletedAt'] != null ? _parseDateTime(json['deletedAt']) : null,
      isQuiz: json['isQuiz'] ?? false,
    );
  }

  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return DateTime.now();
    
    if (dateTime is DateTime) return dateTime;
    
    if (dateTime is String) {
      try {
        return DateTime.parse(dateTime);
      } catch (e) {
        return DateTime.now();
      }
    }
    
    // Handle Firestore Timestamp
    if (dateTime.toString().contains('Timestamp')) {
      try {
        // Extract seconds and nanoseconds from Timestamp string
        final timestampStr = dateTime.toString();
        final match = RegExp(r'Timestamp\(seconds=(\d+), nanoseconds=(\d+)\)').firstMatch(timestampStr);
        if (match != null) {
          final seconds = int.parse(match.group(1)!);
          final nanoseconds = int.parse(match.group(2)!);
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000 + (nanoseconds / 1000000).round());
        }
      } catch (e) {
        print('Error parsing Firestore Timestamp: $e');
      }
    }
    
    return DateTime.now();
  }
}

class QuestionType {
  final String type;
  final String label;
  final IconData icon;
  final String description;

  const QuestionType({
    required this.type,
    required this.label,
    required this.icon,
    required this.description,
  });
}

const List<QuestionType> questionTypes = [
  QuestionType(
    type: 'short_answer',
    label: 'Short Answer',
    icon: Icons.short_text,
    description: 'Single line text input',
  ),
  QuestionType(
    type: 'paragraph',
    label: 'Paragraph',
    icon: Icons.notes,
    description: 'Multi-line text input',
  ),
  QuestionType(
    type: 'multiple_choice',
    label: 'Multiple Choice',
    icon: Icons.radio_button_checked,
    description: 'Single selection from options',
  ),
  QuestionType(
    type: 'checkboxes',
    label: 'Checkboxes',
    icon: Icons.check_box,
    description: 'Multiple selections from options',
  ),
  QuestionType(
    type: 'dropdown',
    label: 'Dropdown',
    icon: Icons.arrow_drop_down_circle,
    description: 'Dropdown selection',
  ),
  QuestionType(
    type: 'email',
    label: 'Email',
    icon: Icons.email,
    description: 'Email address input',
  ),
  QuestionType(
    type: 'number',
    label: 'Number',
    icon: Icons.numbers,
    description: 'Numeric input',
  ),
  QuestionType(
    type: 'date',
    label: 'Date',
    icon: Icons.calendar_today,
    description: 'Date picker',
  ),
  QuestionType(
    type: 'time',
    label: 'Time',
    icon: Icons.access_time,
    description: 'Time picker',
  ),
  QuestionType(
    type: 'rating',
    label: 'Rating Scale',
    icon: Icons.star,
    description: 'Star or numeric rating',
  ),
  QuestionType(
    type: 'true_false',
    label: 'True/False',
    icon: Icons.check_circle_outline,
    description: 'True or false question',
  ),
];
