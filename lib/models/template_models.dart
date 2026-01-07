import 'package:flutter/material.dart';
import 'form_models.dart';

class FormTemplate {
  final String id;
  final String name;
  final String description;
  final String category;
  final IconData icon;
  final Color color;
  final List<FormQuestion> questions;
  final Map<String, dynamic> settings;
  final bool isPremium;
  final List<String> tags;

  const FormTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.icon,
    required this.color,
    required this.questions,
    required this.settings,
    this.isPremium = false,
    this.tags = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'questions': questions.map((q) => q.toJson()).toList(),
      'settings': settings,
      'isPremium': isPremium,
      'tags': tags,
    };
  }

  factory FormTemplate.fromJson(Map<String, dynamic> json) {
    return FormTemplate(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'General',
      icon: Icons.description_outlined, // Default icon
      color: Colors.blue, // Default color
      questions: (json['questions'] as List?)
          ?.map((q) => FormQuestion.fromJson(q))
          .toList() ?? [],
      settings: json['settings'] ?? {},
      isPremium: json['isPremium'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
    );
  }

  FormTemplate copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    IconData? icon,
    Color? color,
    List<FormQuestion>? questions,
    Map<String, dynamic>? settings,
    bool? isPremium,
    List<String>? tags,
  }) {
    return FormTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      questions: questions ?? this.questions,
      settings: settings ?? this.settings,
      isPremium: isPremium ?? this.isPremium,
      tags: tags ?? this.tags,
    );
  }
}

class TemplateCategory {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  const TemplateCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// Template categories
const List<TemplateCategory> templateCategories = [
  TemplateCategory(
    id: 'general',
    name: 'General',
    description: 'Common form templates',
    icon: Icons.description_outlined,
    color: Colors.blue,
  ),
  TemplateCategory(
    id: 'contact',
    name: 'Contact & Information',
    description: 'Contact forms and data collection',
    icon: Icons.contact_page_outlined,
    color: Colors.green,
  ),
  TemplateCategory(
    id: 'registration',
    name: 'Registration',
    description: 'Event and service registration forms',
    icon: Icons.app_registration_outlined,
    color: Colors.orange,
  ),
  TemplateCategory(
    id: 'feedback',
    name: 'Feedback & Surveys',
    description: 'Customer feedback and survey forms',
    icon: Icons.feedback_outlined,
    color: Colors.purple,
  ),
  TemplateCategory(
    id: 'education',
    name: 'Education',
    description: 'School and educational forms',
    icon: Icons.school_outlined,
    color: Colors.teal,
  ),
  TemplateCategory(
    id: 'business',
    name: 'Business',
    description: 'Business and corporate forms',
    icon: Icons.business_outlined,
    color: Colors.indigo,
  ),
  TemplateCategory(
    id: 'healthcare',
    name: 'Healthcare',
    description: 'Medical and health-related forms',
    icon: Icons.local_hospital_outlined,
    color: Colors.red,
  ),
];
