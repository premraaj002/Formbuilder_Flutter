import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;
import '../widgets/public_question_widgets.dart';
import '../services/auth_service.dart';
import 'form_success_screen.dart';

class PublicFormScreen extends StatefulWidget {
  final String formId;
  const PublicFormScreen({super.key, required this.formId});

  @override
  State<PublicFormScreen> createState() => _PublicFormScreenState();
}

class _PublicFormScreenState extends State<PublicFormScreen> {
  Map<String, dynamic>? formData;
  Map<String, dynamic> answers = {};
  bool isLoading = true;
  bool isSubmitting = false;
  bool isSaving = false;
  DateTime? lastSaved;
  User? currentUser;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    // Initialize current user state
    currentUser = FirebaseAuth.instance.currentUser;
    
    // Listen to auth state changes
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      print('Auth state changed: ${user?.email ?? 'null'}');
      if (mounted) {
        setState(() {
          currentUser = user;
        });
        
        // Load existing response when user logs in
        if (user != null) {
          _loadExistingResponse();
        }
      }
    });
    
    _loadForm();
    _loadExistingResponse();
  }

  Future<void> _loadForm() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('forms')
          .doc(widget.formId)
          .get();
      
      if (doc.exists) {
        final data = doc.data();
        // Check if the form is published, default to true for backward compatibility
        final isPublished = data?['isPublished'] ?? true;
        
        setState(() {
          formData = data;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Form not found')));
        }
      }
    } catch (e) {
      print('Error loading form: $e');
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading form: ${e.toString()}')));
      }
    }
  }

  void _updateAnswer(String questionId, dynamic value) {
    setState(() {
      answers[questionId] = value;
    });
    // Save answer incrementally to Firestore as draft
    _saveDraftResponse();
  }

  Future<void> _loadExistingResponse() async {
    if (currentUser == null) return;
    
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('responses')
          .where('formId', isEqualTo: widget.formId)
          .where('userId', isEqualTo: currentUser!.uid)
          .where('isDraft', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        if (data['answers'] != null) {
          setState(() {
            answers = Map<String, dynamic>.from(data['answers']);
          });
        }
      }
    } catch (e) {
      print('Error loading existing response: $e');
    }
  }

  Future<void> _saveDraftResponse() async {
    if (currentUser == null) return;
    
    try {
      final draftData = {
        'formId': widget.formId,
        'userId': currentUser!.uid,
        'userEmail': currentUser!.email,
        'answers': answers,
        'isDraft': true,
        'lastSaved': Timestamp.now(),
        'formOwnerId': formData?['createdBy'],
        'formTitle': formData?['title'],
      };

      // Check if draft already exists
      final querySnapshot = await FirebaseFirestore.instance
          .collection('responses')
          .where('formId', isEqualTo: widget.formId)
          .where('userId', isEqualTo: currentUser!.uid)
          .where('isDraft', isEqualTo: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Update existing draft
        await querySnapshot.docs.first.reference.update(draftData);
      } else {
        // Create new draft
        await FirebaseFirestore.instance.collection('responses').add(draftData);
      }
      
      setState(() {
        lastSaved = DateTime.now();
      });
    } catch (e) {
      print('Error saving draft: $e');
    }
  }

  Future<void> _submitResponse() async {
    // Force refresh auth state before submission
    await _refreshAuthState();
    
    // Check if user is logged in
    print('Submit clicked. Current user: ${currentUser?.email ?? 'null'}');
    if (currentUser == null) {
      print('No user found, showing login prompt');
      _showLoginPrompt();
      return;
    }

    // Validate required fields
    final validationError = _validateRequiredFields();
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validationError),
          backgroundColor: Colors.orange[600],
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      final user = currentUser!;
      
      // Check if user already submitted a response (prevent duplicates)
      final existingResponseQuery = await FirebaseFirestore.instance
          .collection('responses')
          .where('formId', isEqualTo: widget.formId)
          .where('userId', isEqualTo: user.uid)
          .where('isDraft', isEqualTo: false)
          .limit(1)
          .get();
      
      if (existingResponseQuery.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('You have already submitted a response to this form'),
              backgroundColor: Colors.orange[600],
            ),
          );
        }
        return;
      }
      
      // Remove any existing draft
      final draftQuery = await FirebaseFirestore.instance
          .collection('responses')
          .where('formId', isEqualTo: widget.formId)
          .where('userId', isEqualTo: user.uid)
          .where('isDraft', isEqualTo: true)
          .get();

      for (var doc in draftQuery.docs) {
        await doc.reference.delete();
      }

      // Prepare response data
      final responseData = {
        'formId': widget.formId,
        'userId': user.uid,
        'userEmail': user.email,
        'userName': user.displayName ?? user.email?.split('@')[0] ?? 'Anonymous',
        'answers': answers,
        'submittedAt': Timestamp.now(),
        'isDraft': false,
        'formOwnerId': formData?['createdBy'],
        'formTitle': formData?['title'],
        'deviceInfo': {
          'platform': Theme.of(context).platform.name,
          'timestamp': DateTime.now().toIso8601String(),
        },
      };

      // Submit final response
      await FirebaseFirestore.instance
          .collection('responses')
          .add(responseData);

      if (mounted) {
        // Navigate to success screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => FormSuccessScreen(
              formTitle: formData!['title'] ?? 'Untitled Form',
              formId: widget.formId,
              isQuiz: false,
            ),
          ),
        );
      }
    } on FirebaseException catch (e) {
      print('Firebase error submitting response: ${e.code} - ${e.message}');
      if (mounted) {
        String errorMessage;
        switch (e.code) {
          case 'permission-denied':
            errorMessage = 'Permission denied. Your Firestore security rules may need updating.';
            print('=== PERMISSION DENIED DEBUG ===');
            print('User: ${currentUser?.email}');
            print('UID: ${currentUser?.uid}');
            print('Email verified: ${currentUser?.emailVerified}');
            print('Please check your Firestore security rules!');
            break;
          case 'network-request-failed':
            errorMessage = 'Network error. Please check your connection and try again.';
            break;
          case 'unavailable':
            errorMessage = 'Service temporarily unavailable. Please try again later.';
            break;
          default:
            errorMessage = 'Error submitting response: ${e.message}';
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
                  Text(
                    'Check Firebase Console > Firestore > Rules',
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
              onPressed: () => _submitResponse(),
            ),
          ),
        );
      }
    } catch (e) {
      print('Unexpected error submitting response: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error occurred. Please try again.'),
            backgroundColor: Colors.red[600],
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _submitResponse(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }
  
  String? _validateRequiredFields() {
    if (formData == null) return 'Form data not loaded';
    
    final questions = List<Map<String, dynamic>>.from(formData!['questions'] ?? []);
    final List<String> missingRequired = [];
    
    for (final question in questions) {
      final required = question['required'] ?? false;
      if (required) {
        final questionId = question['id'] ?? '';
        final questionTitle = question['title'] ?? question['question'] ?? 'Question';
        final answer = answers[questionId];
        
        if (answer == null || 
            (answer is String && answer.trim().isEmpty) ||
            (answer is List && answer.isEmpty)) {
          missingRequired.add(questionTitle);
        }
      }
    }
    
    if (missingRequired.isNotEmpty) {
      if (missingRequired.length == 1) {
        return 'Please answer the required question: ${missingRequired.first}';
      } else {
        return 'Please answer all required questions (${missingRequired.length} missing)';
      }
    }
    
    return null; // No validation errors
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
                'You need to sign in to submit this form.',
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
        // Refresh auth state and reload existing response after login
        await _refreshAuthState();
        await _loadExistingResponse();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Signed in successfully!'),
              ],
            ),
            backgroundColor: Colors.green[600],
          ),
        );
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
              'Your progress will be saved and you can continue later by logging in again.',
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
      // Save current progress before logging out
      await _saveDraftResponse();
      
      // Sign out
      await FirebaseAuth.instance.signOut();
      
      // Clear current answers to prevent confusion
      setState(() {
        answers = {};
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info, color: Colors.white),
              SizedBox(width: 8),
              Text('Logged out successfully. Progress saved.'),
            ],
          ),
          backgroundColor: Colors.blue[600],
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

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refreshAuthState() async {
    print('Refreshing auth state...');
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await user.reload();
    }
    
    final refreshedUser = FirebaseAuth.instance.currentUser;
    print('Auth state refreshed: ${refreshedUser?.email ?? 'null'}');
    
    if (mounted) {
      setState(() {
        currentUser = refreshedUser;
      });
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  Widget _buildQuestionWidget(Map<String, dynamic> question) {
    final questionId = question['id'] ?? '';
    final questionText = question['title'] ?? question['question'] ?? '';
    final questionType = question['type'] ?? 'text';
    final options = List<String>.from(question['options'] ?? []);
    final required = question['required'] ?? false;

    switch (questionType) {
      case 'short_answer':
      case 'text':
        return TextQuestionWidget(
          question: questionText,
          onChanged: (value) => _updateAnswer(questionId, value),
          required: required,
          initialValue: answers[questionId],
        );
      case 'paragraph':
        return ParagraphQuestionWidget(
          question: questionText,
          onChanged: (value) => _updateAnswer(questionId, value),
          required: required,
          initialValue: answers[questionId],
        );
      case 'multiple_choice':
        return RadioQuestionWidget(
          question: questionText,
          options: options,
          onChanged: (value) => _updateAnswer(questionId, value),
          required: required,
          initialValue: answers[questionId],
        );
      case 'checkboxes':
        return CheckboxQuestionWidget(
          question: questionText,
          options: options,
          onChanged: (value) => _updateAnswer(questionId, value),
          required: required,
          initialValue: answers[questionId] != null 
              ? List<String>.from(answers[questionId]) 
              : null,
        );
      case 'dropdown':
        return DropdownQuestionWidget(
          question: questionText,
          options: options,
          onChanged: (value) => _updateAnswer(questionId, value),
          required: required,
          initialValue: answers[questionId],
        );
      case 'email':
        return EmailQuestionWidget(
          question: questionText,
          onChanged: (value) => _updateAnswer(questionId, value),
          required: required,
          initialValue: answers[questionId],
        );
      case 'number':
        return NumberQuestionWidget(
          question: questionText,
          onChanged: (value) => _updateAnswer(questionId, value),
          required: required,
          initialValue: answers[questionId],
        );
      case 'date':
        return DateQuestionWidget(
          question: questionText,
          onChanged: (value) => _updateAnswer(questionId, value),
          required: required,
          initialValue: answers[questionId],
        );
      case 'time':
        return TimeQuestionWidget(
          question: questionText,
          onChanged: (value) => _updateAnswer(questionId, value),
          required: required,
          initialValue: answers[questionId],
        );
      case 'rating':
        return RatingQuestionWidget(
          question: questionText,
          onChanged: (value) => _updateAnswer(questionId, value),
          required: required,
          initialValue: answers[questionId],
        );
      case 'true_false':
        return TrueFalseQuestionWidget(
          question: questionText,
          onChanged: (value) => _updateAnswer(questionId, value),
          required: required,
          initialValue: answers[questionId],
        );
      default:
        return TextQuestionWidget(
          question: questionText,
          onChanged: (value) => _updateAnswer(questionId, value),
          required: required,
          initialValue: answers[questionId],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Force light theme for this screen only
    return Theme(
      data: ThemeData.light().copyWith(
        primaryColor: Colors.blue,
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
            'Loading Form...',
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
                  color: Colors.blue[50],
                  shape: BoxShape.circle,
                ),
                child: CircularProgressIndicator(
                  color: Colors.blue[600],
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Loading form...',
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

    if (formData == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'Form Not Found',
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
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search_off,
                    size: 64,
                    color: Colors.red[400],
                  ),
                ),
                SizedBox(height: 32),
                Text(
                  'Form Not Found',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'This form could not be found or is no longer available.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back),
                  label: Text('Go Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final questions = List<Map<String, dynamic>>.from(formData!['questions'] ?? []);
    final isPublished = formData!['isPublished'] ?? false;

    if (!isPublished) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'Form Unavailable',
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
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.schedule,
                    size: 64,
                    color: Colors.orange[400],
                  ),
                ),
                SizedBox(height: 32),
                Text(
                  'Form Not Published',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'This form is not published yet. Please check back later or contact the form creator.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.arrow_back),
                  label: Text('Go Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[800],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          // Modern app bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            iconTheme: IconThemeData(color: Colors.grey[800]),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: 16, bottom: 16, right: 16),
              title: Text(
                formData!['title'] ?? 'Untitled Form',
                style: TextStyle(
                  color: Colors.grey[800],
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.blue[50]!,
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              // User authentication section
              if (currentUser == null)
                Container(
                  margin: EdgeInsets.only(right: 16),
                  child: TextButton.icon(
                    onPressed: () => _showLoginPrompt(),
                    icon: Icon(Icons.login, size: 18),
                    label: Text('Login'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.blue[600],
                      backgroundColor: Colors.blue[50],
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  margin: EdgeInsets.only(right: 16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.account_circle, size: 16, color: Colors.green[600]),
                            SizedBox(width: 6),
                            Text(
                              currentUser?.email?.split('@')[0] ?? 'User',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _showLogoutDialog(),
                        icon: Icon(Icons.logout, size: 18, color: Colors.grey[600]),
                        tooltip: 'Logout',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[50],
                          padding: EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          // Form content
          SliverToBoxAdapter(
            child: Container(
              constraints: BoxConstraints(maxWidth: 800),
              margin: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width > 600 ? 32 : 16,
              ),
              child: Column(
                children: [
                  SizedBox(height: 24),
                  
                  // Form description card
                  if (formData!['description'] != null && formData!['description'].isNotEmpty)
                    Container(
                      width: double.infinity,
                      margin: EdgeInsets.only(bottom: 32),
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.08),
                            spreadRadius: 0,
                            blurRadius: 20,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue[600], size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                          Text(
                            formData!['description'],
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                              height: 1.6,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Questions
                  ...questions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final question = entry.value;
                    return Container(
                      margin: EdgeInsets.only(bottom: 24),
                      child: Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.grey[200]!),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                Colors.grey[50]!,
                              ],
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Question number and required indicator
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: Colors.blue[700],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  if (question['required'] == true)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.red[200]!),
                                      ),
                                      child: Text(
                                        'Required',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red[600],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: 16),
                              _buildQuestionWidget(question),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),

                  SizedBox(height: 32),

                  // Action buttons section
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        // Save progress button (for logged in users)
                        if (currentUser != null) ...[
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: isSaving ? null : () async {
                                setState(() => isSaving = true);
                                await _saveDraftResponse();
                                setState(() => isSaving = false);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                                        SizedBox(width: 12),
                                        Text('Progress saved successfully!'),
                                      ],
                                    ),
                                    backgroundColor: Colors.green[600],
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              },
                              icon: isSaving 
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue[600]),
                                  )
                                : Icon(Icons.bookmark_border, size: 18),
                              label: Text(
                                isSaving ? 'Saving Progress...' : 'Save Progress',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.blue[600],
                                side: BorderSide(color: Colors.blue[300]!, width: 1.5),
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          
                          // Last saved indicator
                          if (lastSaved != null) ...[
                            SizedBox(height: 12),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.green[200]!),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.cloud_done, color: Colors.green[600], size: 16),
                                  SizedBox(width: 8),
                                  Text(
                                    'Last saved: ${_formatDateTime(lastSaved!)}',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          SizedBox(height: 16),
                        ],

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isSubmitting ? null : _submitResponse,
                            icon: isSubmitting
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(
                                  currentUser == null ? Icons.login : Icons.send_rounded,
                                  size: 20,
                                ),
                            label: Text(
                              isSubmitting
                                ? 'Submitting Response...'
                                : currentUser == null
                                  ? 'Login to Submit'
                                  : 'Submit Response',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: currentUser == null ? Colors.orange[600] : Colors.blue[600],
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 18),
                              elevation: 0,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),

                        // Login prompt for non-authenticated users
                        if (currentUser == null) ...[
                          SizedBox(height: 16),
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange[200]!),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.orange[600], size: 20),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Sign in to save your responses and submit the form',
                                        style: TextStyle(
                                          color: Colors.orange[800],
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _navigateToLogin,
                                        icon: Icon(Icons.email, size: 16),
                                        label: Text(
                                          'Email Login',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.orange[700],
                                          side: BorderSide(color: Colors.orange[300]!),
                                          padding: EdgeInsets.symmetric(vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _signInWithGoogle,
                                        icon: Icon(Icons.login, size: 16),
                                        label: Text(
                                          'Google',
                                          style: TextStyle(fontSize: 14),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.orange[700],
                                          side: BorderSide(color: Colors.orange[300]!),
                                          padding: EdgeInsets.symmetric(vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Bottom padding
                  SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
