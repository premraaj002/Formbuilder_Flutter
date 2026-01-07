import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import '../widgets/public_quiz_question_widget.dart';
import '../services/auth_service.dart';
import 'form_success_screen.dart';

class PublicQuizScreen extends StatefulWidget {
  final String quizId;
  const PublicQuizScreen({super.key, required this.quizId});

  @override
  State<PublicQuizScreen> createState() => _PublicQuizScreenState();
}

class _PublicQuizScreenState extends State<PublicQuizScreen> {
  Map<String, dynamic>? quizData;
  Map<String, dynamic> answers = {};
  bool isLoading = true;
  bool isSubmitting = false;
  User? currentUser;
  StreamSubscription<User?>? _authSubscription;

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
        final data = doc.data();
        // Check if the quiz is published, default to true for backward compatibility
        final isPublished = data?['isPublished'] ?? true;
        
        setState(() {
          quizData = data;
          isLoading = false;
        });
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
      
      final questions = List<Map<String, dynamic>>.from(quizData!['questions'] ?? []);
      for (var question in questions) {
        final questionId = question['id'] ?? '';
        final correctAnswer = question['correctAnswer'];
        final userAnswer = answers[questionId];
        
        if (correctAnswer != null && userAnswer != null) {
          totalQuestions++;
          if (userAnswer.toString() == correctAnswer.toString()) {
            correctAnswers++;
          }
        }
      }
      
      final score = totalQuestions > 0 ? (correctAnswers / totalQuestions * 100).round() : 0;

      final responseData = {
        'quizId': widget.quizId,
        'userId': currentUser!.uid,
        'userEmail': currentUser!.email,
        'answers': answers,
        'score': score,
        'correctAnswers': correctAnswers,
        'totalQuestions': totalQuestions,
        'submittedAt': Timestamp.now(),
        'quizOwnerId': quizData?['createdBy'],
        'quizTitle': quizData?['title'],
      };

      await FirebaseFirestore.instance
          .collection('quiz_responses')
          .add(responseData);

      if (mounted) {
        // Navigate to success screen with quiz results
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => FormSuccessScreen(
              formTitle: quizData!['title'] ?? 'Untitled Quiz',
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

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Widget _buildQuestionWidget(Map<String, dynamic> question, int index) {
    final questionId = question['id'] ?? '';
    final questionText = question['question'] ?? '';
    final options = List<String>.from(question['options'] ?? []);

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
    if (isLoading) {
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

    if (quizData == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Quiz Not Found'),
          backgroundColor: Colors.red[600],
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('This quiz could not be found or is no longer available.'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final questions = List<Map<String, dynamic>>.from(quizData!['questions'] ?? []);
    final isPublished = quizData!['isPublished'] ?? false;

    if (!isPublished) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Quiz Unavailable'),
          backgroundColor: Colors.orange[600],
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text('This quiz is not published yet.'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(quizData!['title'] ?? 'Untitled Quiz'),
        backgroundColor: Colors.purple[600],
        foregroundColor: Colors.white,
        actions: [
          if (currentUser == null)
            Container(
              margin: EdgeInsets.only(right: 8),
              child: ElevatedButton.icon(
                onPressed: () => _showLoginPrompt(),
                icon: Icon(Icons.login, size: 18),
                label: Text('Login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.purple[600],
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
            )
          else
            // User info and logout
            Container(
              margin: EdgeInsets.only(right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.account_circle, size: 18, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          currentUser?.email?.split('@')[0] ?? 'User',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showLogoutDialog(),
                    icon: Icon(Icons.logout, size: 20),
                    tooltip: 'Logout',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      padding: EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quiz description
            if (quizData!['description'] != null && quizData!['description'].isNotEmpty)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                margin: EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.purple[200]!),
                ),
                child: Text(
                  quizData!['description'],
                  style: TextStyle(fontSize: 16),
                ),
              ),

            // Questions
            ...questions.asMap().entries.map((entry) {
              final index = entry.key;
              final question = entry.value;
              return Container(
                margin: EdgeInsets.only(bottom: 24),
                child: _buildQuestionWidget(question, index),
              );
            }).toList(),

            SizedBox(height: 32),

            // Submit button
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submitQuiz,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple[600],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isSubmitting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Submitting...'),
                        ],
                      )
                    : Text(
                        currentUser == null
                            ? 'Login to Submit Quiz'
                            : 'Submit Quiz',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),

            // Login prompt for non-authenticated users
            if (currentUser == null)
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(top: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange[600]),
                        SizedBox(width: 8),
                        Text(
                          'Login Required',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'You need to login to submit this quiz. Your answers will be saved once you login.',
                      style: TextStyle(color: Colors.orange[700]),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
