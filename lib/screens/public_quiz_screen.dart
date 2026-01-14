import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import '../widgets/public_quiz_question_widget.dart';
import '../services/auth_service.dart';
import '../models/form_models.dart';
import '../models/quiz_settings_model.dart';
import 'form_success_screen.dart';

class PublicQuizScreen extends StatefulWidget {
  final String quizId;
  const PublicQuizScreen({super.key, required this.quizId});

  @override
  State<PublicQuizScreen> createState() => _PublicQuizScreenState();
}

class _PublicQuizScreenState extends State<PublicQuizScreen> {
  // Quiz state
  FormData? quizDetails;
  Map<String, dynamic> answers = {};
  bool isLoading = true;
  bool isSubmitting = false;
  User? currentUser;
  StreamSubscription<User?>? _authSubscription;
  
  // Settings shortcut (will be populated from quizDetails.quizSettings)
  QuizSettingsModel? _settings;
  
  // Timer variables
  Timer? _quizTimer;
  int _remainingSeconds = 0;
  
  // Tab switch restriction variables
  int _tabSwitchCount = 0;
  StreamSubscription? _visibilitySubscription;
  
  // Shuffled data
  List<FormQuestion> _displayQuestions = [];
  Map<String, List<String>> _shuffledOptions = {};

  @override
  void initState() {
    super.initState();
    // Initialize current user state
    currentUser = FirebaseAuth.instance.currentUser;
    
    // Listen to auth state changes
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      print('Quiz - Auth state changed: ${user?.email ?? 'null'}');
      if (mounted) {
        setState(() {
          currentUser = user;
        });
      }
    });
    
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('forms')
          .doc(widget.quizId)
          .get();
      
      if (doc.exists) {
        final formData = FormData.fromJson(doc.data()!);
        final settings = formData.quizSettings ?? QuizSettingsModel();
        
        // Prepare questions (with shuffling if enabled)
        List<FormQuestion> questions = List.from(formData.questions);
        if (settings.shuffleQuestions) {
          questions.shuffle();
        }
        
        // Prepare options (with shuffling if enabled)
        Map<String, List<String>> shuffledOptions = {};
        for (var question in questions) {
          if (question.options != null && question.options!.isNotEmpty) {
            List<String> options = List.from(question.options!);
            if (settings.shuffleOptions) {
              options.shuffle();
            }
            shuffledOptions[question.id] = options;
          }
        }
        
        setState(() {
          quizDetails = formData;
          _settings = settings;
          _displayQuestions = questions;
          _shuffledOptions = shuffledOptions;
          isLoading = false;
        });
        
        // Initialize timer if enabled
        if (settings.timeLimitMinutes != null && settings.timeLimitMinutes! > 0) {
          _remainingSeconds = settings.timeLimitMinutes! * 60;
          _startQuizTimer();
        }
        
        // Initialize tab switch detection if enabled (Web only)
        if (settings.enableTabRestriction) {
          _initializeTabSwitchDetection();
        }
      } else {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Quiz not found')));
        }
      }
    } catch (e) {
      print('Error loading quiz: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading quiz: ${e.toString()}')));
      }
    }
  }

  void _updateAnswer(String questionId, dynamic value) {
    setState(() {
      answers[questionId] = value;
    });
  }

  Future<void> _submitQuiz() async {
    // Force refresh auth state before submission
    await _refreshAuthState();
    
    // Cancel timer if active
    _quizTimer?.cancel();
    
    // Check if user is logged in
    print('Quiz Submit clicked. Current user: ${currentUser?.email ?? 'null'}');
    if (currentUser == null) {
      print('No user found for quiz, showing login prompt');
      _showLoginPrompt();
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // Calculate score
      int correctAnswers = 0;
      int totalQuestions = 0;
      double earnedPoints = 0;
      double totalPoints = 0;
      
      final settings = _settings ?? QuizSettingsModel();
      
      for (var question in quizDetails!.questions) {
        final questionId = question.id;
        final userAnswer = answers[questionId];
        final points = (question.points ?? 1).toDouble();
        totalPoints += points;
        totalQuestions++;

        bool isCorrect = false;
        if (question.type == 'checkboxes') {
          // Handle multiple answers
          final userAnswers = (userAnswer as List?)?.map((e) => e.toString()).toList() ?? [];
          final correctAnswersList = question.correctAnswers?.map((e) => e.toString()).toList() ?? [];
          
          if (userAnswers.length == correctAnswersList.length &&
              userAnswers.every((element) => correctAnswersList.contains(element))) {
            isCorrect = true;
          }
        } else {
          // Handle single answer
          if (userAnswer != null && question.correctAnswer != null &&
              userAnswer.toString().trim().toLowerCase() == 
              question.correctAnswer.toString().trim().toLowerCase()) {
            isCorrect = true;
          }
        }

        if (isCorrect) {
          correctAnswers++;
          earnedPoints += points;
        } else if (userAnswer != null) {
          // Apply negative marking if user answered incorrectly (not skipped)
          if (settings.negativeMarking) {
            earnedPoints -= settings.negativeMarkingPoints;
          }
        }
      }
      
      // Ensure score isn't negative
      if (earnedPoints < 0) earnedPoints = 0;
      
      final score = totalPoints > 0 ? (earnedPoints / totalPoints * 100).round() : 0;

      final responseData = {
        'quizId': widget.quizId,
        'userId': currentUser!.uid,
        'userEmail': currentUser!.email,
        'answers': answers,
        'score': score,
        'earnedPoints': earnedPoints,
        'totalPoints': totalPoints,
        'correctAnswers': correctAnswers,
        'totalQuestions': totalQuestions,
        'submittedAt': Timestamp.now(),
        'quizOwnerId': quizDetails?.createdBy,
        'quizTitle': quizDetails?.title,
      };

      await FirebaseFirestore.instance
          .collection('quiz_responses')
          .add(responseData);

      if (mounted) {
        // Navigate to success screen with quiz results
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => FormSuccessScreen(
              formTitle: quizDetails!.title,
              formId: widget.quizId,
              isQuiz: true,
              score: score,
              totalQuestions: totalQuestions,
            ),
          ),
        );
      }
    } on FirebaseException catch (e) {
      print('Firebase error submitting quiz: ${e.code} - ${e.message}');
      if (mounted) {
        String errorMessage;
        switch (e.code) {
          case 'permission-denied':
            errorMessage = 'Permission denied. Your Firestore security rules may need updating.';
            print('=== QUIZ PERMISSION DENIED DEBUG ===');
            print('User: ${currentUser?.email}');
            print('UID: ${currentUser?.uid}');
            print('Please check your Firestore security rules!');
            break;
          case 'network-request-failed':
            errorMessage = 'Network error. Please check your connection and try again.';
            break;
          default:
            errorMessage = 'Error submitting quiz: ${e.message}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(errorMessage),
                if (e.code == 'permission-denied') ...[
                  SizedBox(height: 4),
                  Text(
                    'Debug: ${currentUser?.email ?? 'No user'} (${currentUser?.uid ?? 'No UID'})',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ],
            ),
            backgroundColor: Colors.red[600],
            duration: Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _submitQuiz(),
            ),
          ),
        );
      }
    } catch (e) {
      print('Unexpected error submitting quiz: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error occurred. Please try again.'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }


  void _showLoginPrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.lock_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 8),
              Text('Login Required'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You need to sign in to submit this quiz.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              SizedBox(height: 16),
              Text(
                'Choose your preferred sign-in method:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _signInWithGoogle();
              },
              icon: Icon(Icons.login, size: 18),
              label: Text('Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.grey[800],
                side: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _navigateToLogin();
              },
              icon: Icon(Icons.email, size: 18),
              label: Text('Email'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Signing in with Google...'),
            ],
          ),
        ),
      );
      
      final userCredential = await AuthService.signInWithGoogle(role: 'student');
      
      // Close loading dialog
      Navigator.pop(context);
      
      if (userCredential?.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Signed in successfully!'),
              ],
            ),
            backgroundColor: Colors.purple[600],
          ),
        );
        
        await _refreshAuthState(); // Refresh UI to show login state
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Google Sign-In failed: ${e.toString()}'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  void _navigateToLogin() {
    // Navigate to student login page
    Navigator.pushNamed(context, '/student-login');
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.logout, color: Colors.orange[600]),
            SizedBox(width: 8),
            Text('Logout'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to logout?'),
            SizedBox(height: 8),
            Text(
              'Your current answers will be lost. Complete the quiz before logging out.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    try {
      // Sign out
      await FirebaseAuth.instance.signOut();
      
      // Clear current answers
      setState(() {
        answers = {};
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info, color: Colors.white),
              SizedBox(width: 8),
              Text('Logged out successfully.'),
            ],
          ),
          backgroundColor: Colors.purple[600],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during logout: ${e.toString()}'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  Future<void> _refreshAuthState() async {
    print('Quiz - Refreshing auth state...');
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
    }
    
    final refreshedUser = FirebaseAuth.instance.currentUser;
    print('Quiz - Auth state refreshed: ${refreshedUser?.email ?? 'null'}');
    
    if (mounted) {
      setState(() {
        currentUser = refreshedUser;
      });
    }
  }
  
  // Timer Management Methods
  void _startQuizTimer() {
    _quizTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
        _autoSubmitQuiz(reason: 'Time expired');
      }
    });
  }
  
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
  
  // Tab Switch Detection Methods
  void _initializeTabSwitchDetection() {
    // Only works on Flutter Web
    if (kIsWeb) {
      _visibilitySubscription = html.document.onVisibilityChange.listen((event) {
        if (html.document.hidden ?? false) {
          _handleTabSwitch();
        }
      });
    }
  }
  
  void _handleTabSwitch() {
    if (_settings == null || !_settings!.enableTabRestriction) return;
    
    setState(() {
      _tabSwitchCount++;
    });
    
    final maxSwitches = _settings?.maxTabSwitchCount ?? 5;
    
    // Show warning dialog
    if (_tabSwitchCount <= maxSwitches) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange[600], size: 28),
              SizedBox(width: 12),
              Text('Tab Switch Detected'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You have switched tabs or minimized the window.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Violation $_tabSwitchCount of $maxSwitches',
                        style: TextStyle(
                          color: Colors.orange[900],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_tabSwitchCount >= maxSwitches)
                Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Text(
                    'This is your final warning. Further violations will auto-submit the quiz.',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
              ),
              child: Text('I Understand'),
            ),
          ],
        ),
      );
    }
    
    // Auto-submit if exceeded
    if (_tabSwitchCount > (_settings?.maxTabSwitchCount ?? 5)) {
      _autoSubmitQuiz(reason: 'Exceeded allowed tab switches (${_settings?.maxTabSwitchCount ?? 5})');
    }
  }
  
  Future<void> _autoSubmitQuiz({required String reason}) async {
    // Cancel timer
    _quizTimer?.cancel();
    
    // Show reason dialog
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[600], size: 28),
              SizedBox(width: 12),
              Text('Quiz Auto-Submitted'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your quiz has been automatically submitted.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red[700]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Reason: $reason',
                        style: TextStyle(
                          color: Colors.red[900],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _submitQuiz();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
                foregroundColor: Colors.white,
              ),
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _quizTimer?.cancel();
    _visibilitySubscription?.cancel();
    super.dispose();
  }

  Widget _buildQuestionWidget(FormQuestion question, int index) {
    final questionId = question.id;
    final questionText = question.title;
    // Use shuffled options if available, otherwise fallback to original
    final options = _shuffledOptions[questionId] ?? question.options ?? [];

    return PublicQuizQuestionWidget(
      questionNumber: index + 1,
      question: questionText,
      options: options,
      onChanged: (value) => _updateAnswer(questionId, value),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Force light theme for this screen only
    return Theme(
      data: ThemeData.light().copyWith(
        primaryColor: Colors.purple,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey[800],
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      child: _buildContent(context),
    );
  }
  
  Widget _buildContent(BuildContext context) {
    if (isLoading || quizDetails == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'Loading Quiz...',
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.grey[800]),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  shape: BoxShape.circle,
                ),
                child: CircularProgressIndicator(
                  color: Colors.purple[600],
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Loading quiz...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    final theme = Theme.of(context);
    final settings = _settings ?? QuizSettingsModel();

    return PopScope(
      canPop: settings.allowBackNavigation,
      onPopInvoked: (didPop) {
        if (didPop) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Back navigation is disabled for this quiz'))
        );
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quizDetails!.title,
                style: TextStyle(
                  color: Colors.grey[900],
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              if (settings.timeLimitMinutes != null)
                Text(
                  'Timer Active • ${_formatTime(_remainingSeconds)}',
                  style: TextStyle(
                    color: _remainingSeconds < 60 ? Colors.red : Colors.purple[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
          actions: [
            if (currentUser != null)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Center(
                  child: Text(
                    currentUser!.email?.split('@')[0] ?? '',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            IconButton(
              onPressed: currentUser != null ? _showLogoutDialog : _showLoginPrompt,
              icon: Icon(
                currentUser != null ? Icons.logout : Icons.login,
                color: Colors.grey[700],
              ),
              tooltip: currentUser != null ? 'Logout' : 'Login',
            ),
          ],
        ),
        body: Column(
          children: [
            if (settings.timeLimitMinutes != null)
              LinearProgressIndicator(
                value: 1 - (_remainingSeconds / (settings.timeLimitMinutes! * 60)),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _remainingSeconds < 60 ? Colors.red : Colors.purple,
                ),
                minHeight: 4,
              ),
            if (settings.negativeMarking)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                color: Colors.red[50],
                child: Text(
                  '⚠️ Negative marking enabled: -${settings.negativeMarkingPoints} per wrong answer',
                  style: TextStyle(color: Colors.red[900], fontSize: 11, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
            if (settings.enableTabRestriction)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                color: Colors.orange[50],
                child: Text(
                  'Tab Switches: $_tabSwitchCount / ${settings.maxTabSwitchCount ?? 5}',
                  style: TextStyle(color: Colors.orange[900], fontSize: 11, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _displayQuestions.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 24),
                    child: _buildQuestionWidget(_displayQuestions[index], index),
                  );
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: isSubmitting ? null : _submitQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isSubmitting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Submit Quiz',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
