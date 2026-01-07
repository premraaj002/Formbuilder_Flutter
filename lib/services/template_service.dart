import 'package:flutter/material.dart';
import '../models/template_models.dart';
import '../models/form_models.dart';

class TemplateService {
  static List<FormTemplate> getAllTemplates() {
    return [
      // Blank template
      const FormTemplate(
        id: 'blank',
        name: 'Blank Form',
        description: 'Start with a blank form and add your own questions',
        category: 'general',
        icon: Icons.description_outlined,
        color: Colors.blue,
        questions: [],
        settings: {},
        tags: ['basic', 'custom'],
      ),

      // Contact Information Template
      FormTemplate(
        id: 'contact_info',
        name: 'Contact Information',
        description: 'Collect basic contact details from users',
        category: 'contact',
        icon: Icons.contact_page_outlined,
        color: Colors.green,
        questions: [
          FormQuestion(
            id: 'full_name',
            type: 'short_answer',
            title: 'Full Name',
            description: 'Enter your first and last name',
            required: true,
            order: 0,
          ),
          FormQuestion(
            id: 'email',
            type: 'email',
            title: 'Email Address',
            description: 'We\'ll use this to contact you',
            required: true,
            order: 1,
          ),
          FormQuestion(
            id: 'phone',
            type: 'short_answer',
            title: 'Phone Number',
            description: 'Include country code if international',
            required: false,
            order: 2,
          ),
          FormQuestion(
            id: 'company',
            type: 'short_answer',
            title: 'Company/Organization',
            description: 'Where do you work?',
            required: false,
            order: 3,
          ),
          FormQuestion(
            id: 'message',
            type: 'paragraph',
            title: 'Message',
            description: 'Tell us how we can help you',
            required: false,
            order: 4,
          ),
        ],
        settings: {
          'collectEmail': true,
          'requireSignIn': false,
          'allowMultipleSubmissions': false,
        },
        tags: ['contact', 'information', 'basic'],
      ),

      // Event Registration Template
      FormTemplate(
        id: 'event_registration',
        name: 'Event Registration',
        description: 'Register attendees for events and conferences',
        category: 'registration',
        icon: Icons.event_outlined,
        color: Colors.orange,
        questions: [
          FormQuestion(
            id: 'attendee_name',
            type: 'short_answer',
            title: 'Attendee Full Name',
            description: 'Name for the registration badge',
            required: true,
            order: 0,
          ),
          FormQuestion(
            id: 'email',
            type: 'email',
            title: 'Email Address',
            description: 'For event updates and confirmations',
            required: true,
            order: 1,
          ),
          FormQuestion(
            id: 'phone',
            type: 'short_answer',
            title: 'Phone Number',
            description: 'Emergency contact number',
            required: true,
            order: 2,
          ),
          FormQuestion(
            id: 'ticket_type',
            type: 'multiple_choice',
            title: 'Ticket Type',
            description: 'Select your registration type',
            required: true,
            options: ['General Admission', 'VIP', 'Student', 'Press'],
            order: 3,
          ),
          FormQuestion(
            id: 'dietary_restrictions',
            type: 'checkboxes',
            title: 'Dietary Restrictions',
            description: 'Select all that apply',
            required: false,
            options: ['None', 'Vegetarian', 'Vegan', 'Gluten-free', 'Nut allergy', 'Other'],
            order: 4,
          ),
          FormQuestion(
            id: 'additional_info',
            type: 'paragraph',
            title: 'Additional Information',
            description: 'Any special requirements or notes',
            required: false,
            order: 5,
          ),
        ],
        settings: {
          'collectEmail': true,
          'requireSignIn': false,
          'confirmationMessage': 'Thank you for registering! You\'ll receive a confirmation email shortly.',
        },
        tags: ['registration', 'event', 'conference'],
      ),

      // Customer Feedback Template
      FormTemplate(
        id: 'customer_feedback',
        name: 'Customer Feedback',
        description: 'Collect customer satisfaction and feedback',
        category: 'feedback',
        icon: Icons.feedback_outlined,
        color: Colors.purple,
        questions: [
          FormQuestion(
            id: 'overall_satisfaction',
            type: 'rating',
            title: 'Overall Satisfaction',
            description: 'How would you rate your overall experience?',
            required: true,
            settings: {'maxRating': 5, 'ratingLabels': ['Poor', 'Fair', 'Good', 'Very Good', 'Excellent']},
            order: 0,
          ),
          FormQuestion(
            id: 'service_quality',
            type: 'multiple_choice',
            title: 'Service Quality',
            description: 'How would you rate our service?',
            required: true,
            options: ['Excellent', 'Good', 'Average', 'Poor', 'Very Poor'],
            order: 1,
          ),
          FormQuestion(
            id: 'product_features',
            type: 'checkboxes',
            title: 'Which features did you find most useful?',
            description: 'Select all that apply',
            required: false,
            options: ['User Interface', 'Performance', 'Customer Support', 'Documentation', 'Pricing'],
            order: 2,
          ),
          FormQuestion(
            id: 'improvements',
            type: 'paragraph',
            title: 'Suggestions for Improvement',
            description: 'What can we do better?',
            required: false,
            order: 3,
          ),
          FormQuestion(
            id: 'recommend',
            type: 'multiple_choice',
            title: 'Would you recommend us to others?',
            description: 'Likelihood to recommend',
            required: true,
            options: ['Definitely', 'Probably', 'Maybe', 'Probably not', 'Definitely not'],
            order: 4,
          ),
          FormQuestion(
            id: 'additional_comments',
            type: 'paragraph',
            title: 'Additional Comments',
            description: 'Any other feedback you\'d like to share',
            required: false,
            order: 5,
          ),
        ],
        settings: {
          'collectEmail': false,
          'anonymous': true,
          'thankYouMessage': 'Thank you for your valuable feedback!',
        },
        tags: ['feedback', 'survey', 'customer'],
      ),

      // Job Application Template
      FormTemplate(
        id: 'job_application',
        name: 'Job Application',
        description: 'Collect applications for job positions',
        category: 'business',
        icon: Icons.work_outlined,
        color: Colors.indigo,
        questions: [
          FormQuestion(
            id: 'full_name',
            type: 'short_answer',
            title: 'Full Name',
            required: true,
            order: 0,
          ),
          FormQuestion(
            id: 'email',
            type: 'email',
            title: 'Email Address',
            required: true,
            order: 1,
          ),
          FormQuestion(
            id: 'phone',
            type: 'short_answer',
            title: 'Phone Number',
            required: true,
            order: 2,
          ),
          FormQuestion(
            id: 'position',
            type: 'dropdown',
            title: 'Position Applied For',
            description: 'Select the position you\'re interested in',
            required: true,
            options: ['Software Developer', 'Product Manager', 'Designer', 'Marketing Specialist', 'Sales Representative', 'Other'],
            order: 3,
          ),
          FormQuestion(
            id: 'experience',
            type: 'multiple_choice',
            title: 'Years of Experience',
            description: 'Total years of relevant work experience',
            required: true,
            options: ['0-1 years', '2-3 years', '4-5 years', '6-10 years', '10+ years'],
            order: 4,
          ),
          FormQuestion(
            id: 'skills',
            type: 'checkboxes',
            title: 'Technical Skills',
            description: 'Select all that apply to you',
            required: false,
            options: ['JavaScript', 'Python', 'Java', 'React', 'Node.js', 'Database Management', 'Cloud Platforms', 'Other'],
            order: 5,
          ),
          FormQuestion(
            id: 'cover_letter',
            type: 'paragraph',
            title: 'Cover Letter',
            description: 'Tell us why you\'re the perfect fit for this role',
            required: true,
            order: 6,
          ),
          FormQuestion(
            id: 'availability',
            type: 'date',
            title: 'Available Start Date',
            description: 'When can you start?',
            required: true,
            order: 7,
          ),
        ],
        settings: {
          'collectEmail': true,
          'requireSignIn': false,
          'fileUpload': true,
        },
        tags: ['job', 'application', 'hiring', 'business'],
      ),

      // Course Enrollment Template
      FormTemplate(
        id: 'course_enrollment',
        name: 'Course Enrollment',
        description: 'Enroll students in courses and programs',
        category: 'education',
        icon: Icons.school_outlined,
        color: Colors.teal,
        questions: [
          FormQuestion(
            id: 'student_name',
            type: 'short_answer',
            title: 'Student Full Name',
            required: true,
            order: 0,
          ),
          FormQuestion(
            id: 'student_id',
            type: 'short_answer',
            title: 'Student ID (if applicable)',
            required: false,
            order: 1,
          ),
          FormQuestion(
            id: 'email',
            type: 'email',
            title: 'Email Address',
            required: true,
            order: 2,
          ),
          FormQuestion(
            id: 'course_selection',
            type: 'multiple_choice',
            title: 'Course Selection',
            description: 'Which course would you like to enroll in?',
            required: true,
            options: ['Introduction to Programming', 'Web Development', 'Data Science', 'Mobile App Development', 'Cybersecurity'],
            order: 3,
          ),
          FormQuestion(
            id: 'experience_level',
            type: 'multiple_choice',
            title: 'Experience Level',
            description: 'What\'s your current skill level?',
            required: true,
            options: ['Beginner', 'Intermediate', 'Advanced'],
            order: 4,
          ),
          FormQuestion(
            id: 'learning_goals',
            type: 'checkboxes',
            title: 'Learning Goals',
            description: 'What do you hope to achieve? (Select all that apply)',
            required: false,
            options: ['Career Change', 'Skill Enhancement', 'Personal Interest', 'Academic Requirements', 'Professional Development'],
            order: 5,
          ),
          FormQuestion(
            id: 'schedule_preference',
            type: 'multiple_choice',
            title: 'Schedule Preference',
            description: 'When would you prefer to attend classes?',
            required: true,
            options: ['Weekday Morning', 'Weekday Evening', 'Weekend', 'Online Only', 'Flexible'],
            order: 6,
          ),
        ],
        settings: {
          'collectEmail': true,
          'requireSignIn': false,
          'confirmationMessage': 'Thank you for enrolling! You\'ll receive course details via email.',
        },
        tags: ['education', 'course', 'enrollment', 'learning'],
      ),

      // Health Intake Template
      FormTemplate(
        id: 'health_intake',
        name: 'Patient Health Intake',
        description: 'Collect patient information for healthcare providers',
        category: 'healthcare',
        icon: Icons.local_hospital_outlined,
        color: Colors.red,
        questions: [
          FormQuestion(
            id: 'patient_name',
            type: 'short_answer',
            title: 'Patient Full Name',
            required: true,
            order: 0,
          ),
          FormQuestion(
            id: 'date_of_birth',
            type: 'date',
            title: 'Date of Birth',
            required: true,
            order: 1,
          ),
          FormQuestion(
            id: 'gender',
            type: 'multiple_choice',
            title: 'Gender',
            required: true,
            options: ['Male', 'Female', 'Other', 'Prefer not to say'],
            order: 2,
          ),
          FormQuestion(
            id: 'contact_phone',
            type: 'short_answer',
            title: 'Phone Number',
            required: true,
            order: 3,
          ),
          FormQuestion(
            id: 'emergency_contact',
            type: 'short_answer',
            title: 'Emergency Contact Name',
            required: true,
            order: 4,
          ),
          FormQuestion(
            id: 'emergency_phone',
            type: 'short_answer',
            title: 'Emergency Contact Phone',
            required: true,
            order: 5,
          ),
          FormQuestion(
            id: 'current_medications',
            type: 'paragraph',
            title: 'Current Medications',
            description: 'List all medications you are currently taking',
            required: false,
            order: 6,
          ),
          FormQuestion(
            id: 'allergies',
            type: 'paragraph',
            title: 'Allergies',
            description: 'List any known allergies',
            required: false,
            order: 7,
          ),
          FormQuestion(
            id: 'medical_history',
            type: 'checkboxes',
            title: 'Medical History',
            description: 'Select all conditions that apply',
            required: false,
            options: ['Diabetes', 'Heart Disease', 'High Blood Pressure', 'Asthma', 'Cancer', 'Mental Health Conditions', 'None'],
            order: 8,
          ),
        ],
        settings: {
          'collectEmail': true,
          'requireSignIn': true,
          'hipaaCompliant': true,
        },
        tags: ['healthcare', 'medical', 'patient', 'intake'],
        isPremium: false,
      ),

      // Quiz Templates
      FormTemplate(
        id: 'math_quiz',
        name: 'Math Quiz',
        description: 'Basic mathematics quiz with multiple choice questions',
        category: 'education',
        icon: Icons.calculate_outlined,
        color: Colors.blue,
        questions: [
          FormQuestion(
            id: 'math_q1',
            type: 'multiple_choice',
            title: 'What is 15 + 27?',
            required: true,
            options: ['40', '42', '44', '45'],
            order: 0,
            isQuizQuestion: true,
            correctAnswer: '42',
            points: 2,
          ),
          FormQuestion(
            id: 'math_q2',
            type: 'multiple_choice',
            title: 'What is 8 × 7?',
            required: true,
            options: ['54', '56', '58', '64'],
            order: 1,
            isQuizQuestion: true,
            correctAnswer: '56',
            points: 2,
          ),
          FormQuestion(
            id: 'math_q3',
            type: 'multiple_choice',
            title: 'What is 100 ÷ 4?',
            required: true,
            options: ['20', '25', '30', '35'],
            order: 2,
            isQuizQuestion: true,
            correctAnswer: '25',
            points: 2,
          ),
        ],
        settings: {
          'showScoreAtEnd': true,
          'totalPoints': 6,
          'timeLimit': 300, // 5 minutes
          'allowRetake': true,
        },
        tags: ['quiz', 'math', 'education'],
      ),

      FormTemplate(
        id: 'trivia_quiz',
        name: 'General Trivia Quiz',
        description: 'Fun general knowledge trivia questions',
        category: 'general',
        icon: Icons.lightbulb_outlined,
        color: Colors.orange,
        questions: [
          FormQuestion(
            id: 'trivia_q1',
            type: 'multiple_choice',
            title: 'What is the capital of France?',
            required: true,
            options: ['London', 'Berlin', 'Paris', 'Madrid'],
            order: 0,
            isQuizQuestion: true,
            correctAnswer: 'Paris',
            points: 1,
          ),
          FormQuestion(
            id: 'trivia_q2',
            type: 'true_false',
            title: 'The Great Wall of China is visible from space.',
            required: true,
            options: ['True', 'False'],
            order: 1,
            isQuizQuestion: true,
            correctAnswer: 'False',
            points: 1,
          ),
          FormQuestion(
            id: 'trivia_q3',
            type: 'multiple_choice',
            title: 'Which planet is closest to the Sun?',
            required: true,
            options: ['Venus', 'Earth', 'Mercury', 'Mars'],
            order: 2,
            isQuizQuestion: true,
            correctAnswer: 'Mercury',
            points: 1,
          ),
          FormQuestion(
            id: 'trivia_q4',
            type: 'multiple_choice',
            title: 'In what year did World War II end?',
            required: true,
            options: ['1944', '1945', '1946', '1947'],
            order: 3,
            isQuizQuestion: true,
            correctAnswer: '1945',
            points: 1,
          ),
        ],
        settings: {
          'showScoreAtEnd': true,
          'totalPoints': 4,
          'shuffleQuestions': true,
          'allowRetake': true,
        },
        tags: ['quiz', 'trivia', 'general knowledge'],
      ),

      FormTemplate(
        id: 'personality_quiz',
        name: 'Personality Quiz',
        description: 'Simple personality assessment quiz',
        category: 'general',
        icon: Icons.psychology_outlined,
        color: Colors.teal,
        questions: [
          FormQuestion(
            id: 'personality_q1',
            type: 'multiple_choice',
            title: 'How do you prefer to spend your free time?',
            required: true,
            options: ['Reading a book', 'Hanging out with friends', 'Exercising', 'Watching movies'],
            order: 0,
            isQuizQuestion: true,
            points: 0, // No scoring for personality quiz
          ),
          FormQuestion(
            id: 'personality_q2',
            type: 'multiple_choice',
            title: 'What motivates you most?',
            required: true,
            options: ['Achievement', 'Recognition', 'Helping others', 'Learning new things'],
            order: 1,
            isQuizQuestion: true,
            points: 0,
          ),
          FormQuestion(
            id: 'personality_q3',
            type: 'multiple_choice',
            title: 'In a group project, you typically:',
            required: true,
            options: ['Take the lead', 'Support others', 'Focus on details', 'Generate ideas'],
            order: 2,
            isQuizQuestion: true,
            points: 0,
          ),
        ],
        settings: {
          'showScoreAtEnd': false,
          'totalPoints': 0,
          'allowRetake': true,
        },
        tags: ['quiz', 'personality', 'assessment'],
      ),

      // Quick Survey Template
      FormTemplate(
        id: 'quick_survey',
        name: 'Quick Survey',
        description: 'A simple 3-question survey template',
        category: 'feedback',
        icon: Icons.poll_outlined,
        color: Colors.amber,
        questions: [
          FormQuestion(
            id: 'satisfaction_rating',
            type: 'rating',
            title: 'How satisfied are you with our service?',
            required: true,
            settings: {'maxRating': 5},
            order: 0,
          ),
          FormQuestion(
            id: 'recommendation',
            type: 'multiple_choice',
            title: 'Would you recommend us to a friend?',
            required: true,
            options: ['Yes', 'No', 'Maybe'],
            order: 1,
          ),
          FormQuestion(
            id: 'comments',
            type: 'paragraph',
            title: 'Additional Comments',
            description: 'Any other thoughts you\'d like to share?',
            required: false,
            order: 2,
          ),
        ],
        settings: {
          'collectEmail': false,
          'anonymous': true,
        },
        tags: ['survey', 'quick', 'feedback', 'simple'],
      ),
    ];
  }

  static List<FormTemplate> getTemplatesByCategory(String category) {
    return getAllTemplates().where((template) => template.category == category).toList();
  }

  static FormTemplate? getTemplateById(String id) {
    try {
      return getAllTemplates().firstWhere((template) => template.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<FormTemplate> getFeaturedTemplates() {
    return [
      getTemplateById('contact_info')!,
      getTemplateById('event_registration')!,
      getTemplateById('customer_feedback')!,
      getTemplateById('quick_survey')!,
    ];
  }

  static List<FormTemplate> searchTemplates(String query) {
    final lowercaseQuery = query.toLowerCase();
    return getAllTemplates().where((template) {
      return template.name.toLowerCase().contains(lowercaseQuery) ||
          template.description.toLowerCase().contains(lowercaseQuery) ||
          template.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }
}
