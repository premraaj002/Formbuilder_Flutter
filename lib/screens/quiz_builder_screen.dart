import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'dart:math';
import '../models/form_models.dart';
import '../models/template_models.dart';
import '../widgets/quiz_question_widget.dart';
import '../utils/responsive.dart';

class QuizBuilderScreen extends StatefulWidget {
  final String? quizId;
  final FormTemplate? template;

  const QuizBuilderScreen({super.key, this.quizId, this.template});

  @override
  _QuizBuilderScreenState createState() => _QuizBuilderScreenState();
}

class QuestionType {
  final String type;
  final String label;
  final IconData icon;
  final String description;

  QuestionType({
    required this.type,
    required this.label,
    required this.icon,
    required this.description,
  });
}

class _QuizBuilderScreenState extends State<QuizBuilderScreen> {
  final _quizTitleController = TextEditingController();
  final _quizDescriptionController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<FormQuestion> _questions = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _selectedQuestionId;
  bool _isPublished = false;
  
  // Quiz-specific settings
  bool _showScoreAtEnd = true;
  bool _shuffleQuestions = false;
  int _timeLimit = 0;
  bool _allowRetake = true;

  @override
  void initState() {
    super.initState();
    if (widget.quizId != null) {
      _loadQuiz();
    } else {
      _initializeQuiz();
    }
  }

  void _initializeQuiz() {
    if (widget.template != null) {
      _quizTitleController.text = widget.template!.name;
      _quizDescriptionController.text = widget.template!.description;
      
      _questions = widget.template!.questions.map((templateQuestion) {
        return FormQuestion(
          id: _generateQuestionId(),
          type: templateQuestion.type,
          title: templateQuestion.title,
          description: templateQuestion.description,
          required: true,
          options: templateQuestion.options?.toList(),
          settings: templateQuestion.settings != null 
              ? Map<String, dynamic>.from(templateQuestion.settings!)
              : null,
          order: templateQuestion.order,
          isQuizQuestion: true,
          correctAnswer: templateQuestion.correctAnswer,
          correctAnswers: templateQuestion.correctAnswers?.toList(),
          points: templateQuestion.points ?? 1,
        );
      }).toList();
      
      final templateSettings = widget.template!.settings;
      _showScoreAtEnd = templateSettings['showScoreAtEnd'] ?? true;
      _shuffleQuestions = templateSettings['shuffleQuestions'] ?? false;
      _timeLimit = templateSettings['timeLimit'] ?? 0;
      _allowRetake = templateSettings['allowRetake'] ?? true;
      
      setState(() {});
    } else {
      _quizTitleController.text = 'Untitled Quiz';
    }
  }

  Future<void> _loadQuiz() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('forms')
          .doc(widget.quizId)
          .get();
      
      if (doc.exists) {
        final formData = FormData.fromJson(doc.data()!);
        _quizTitleController.text = formData.title;
        _quizDescriptionController.text = formData.description ?? '';
        _questions = formData.questions;
        final settings = formData.settings;
        _showScoreAtEnd = settings['showScoreAtEnd'] ?? true;
        _shuffleQuestions = settings['shuffleQuestions'] ?? false;
        _timeLimit = settings['timeLimit'] ?? 0;
        _allowRetake = settings['allowRetake'] ?? true;
        _isPublished = (doc.data()!['isPublished'] ?? false) as bool;
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading quiz: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _generateQuestionId() {
    return 'q_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  void _addQuizQuestion(String type) {
    final newQuestion = FormQuestion(
      id: _generateQuestionId(),
      type: type,
      title: _getDefaultQuestionTitle(type),
      required: true,
      order: _questions.length,
      options: _needsOptions(type) ? _getDefaultOptions(type) : null,
      isQuizQuestion: true,
      points: 1,
      correctAnswer: type == 'true_false' ? 'True' : null,
    );

    setState(() {
      _questions.add(newQuestion);
      _selectedQuestionId = newQuestion.id;
    });

    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  String _getDefaultQuestionTitle(String type) {
    switch (type) {
      case 'short_answer':
        return 'Short answer text';
      case 'paragraph':
        return 'Long answer text';
      case 'multiple_choice':
        return 'Multiple choice question';
      case 'checkboxes':
        return 'Checkbox question';
      case 'dropdown':
        return 'Dropdown question';
      case 'email':
        return 'Email address';
      case 'number':
        return 'Number';
      case 'date':
        return 'Date';
      case 'time':
        return 'Time';
      case 'rating':
        return 'Rating scale';
      case 'true_false':
        return 'True or False question';
      default:
        return 'Quiz Question';
    }
  }

  List<String>? _getDefaultOptions(String type) {
    switch (type) {
      case 'multiple_choice':
        return ['Option 1', 'Option 2', 'Option 3', 'Option 4'];
      case 'checkboxes':
        return ['Option 1', 'Option 2', 'Option 3'];
      case 'dropdown':
        return ['Option 1', 'Option 2', 'Option 3'];
      case 'true_false':
        return ['True', 'False'];
      default:
        return null;
    }
  }
  
  bool _needsOptions(String type) {
    return ['multiple_choice', 'checkboxes', 'dropdown', 'true_false'].contains(type);
  }

  void _updateQuestion(FormQuestion updatedQuestion) {
    setState(() {
      final index = _questions.indexWhere((q) => q.id == updatedQuestion.id);
      if (index != -1) {
        _questions[index] = updatedQuestion;
      }
    });
  }

  void _deleteQuestion(String questionId) {
    setState(() {
      _questions.removeWhere((q) => q.id == questionId);
      if (_selectedQuestionId == questionId) {
        _selectedQuestionId = null;
      }
      for (int i = 0; i < _questions.length; i++) {
        _questions[i] = _questions[i].copyWith(order: i);
      }
    });
  }
  
  void _duplicateQuestion(String questionId) {
    final originalQuestion = _questions.firstWhere((q) => q.id == questionId);
    final duplicatedQuestion = FormQuestion(
      id: _generateQuestionId(),
      type: originalQuestion.type,
      title: '${originalQuestion.title} (Copy)',
      description: originalQuestion.description,
      required: originalQuestion.required,
      options: originalQuestion.options?.toList(),
      settings: Map.from(originalQuestion.settings ?? {}),
      order: originalQuestion.order + 1,
      isQuizQuestion: true,
      correctAnswer: originalQuestion.correctAnswer,
      correctAnswers: originalQuestion.correctAnswers?.toList(),
      points: originalQuestion.points ?? 1,
    );

    setState(() {
      final insertIndex = originalQuestion.order + 1;
      _questions.insert(insertIndex, duplicatedQuestion);
      for (int i = insertIndex + 1; i < _questions.length; i++) {
        _questions[i] = _questions[i].copyWith(order: i);
      }
    });
  }

  Future<void> _saveQuiz({bool publish = false}) async {
    if (_quizTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a quiz title')),
      );
      return;
    }

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add at least one question')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final now = DateTime.now();
      
      final totalPoints = _questions.fold(0, (sum, q) => sum + (q.points ?? 1));
      
      final formData = FormData(
        id: widget.quizId,
        title: _quizTitleController.text.trim(),
        description: _quizDescriptionController.text.trim(),
        questions: _questions,
        settings: {
          'showScoreAtEnd': _showScoreAtEnd,
          'shuffleQuestions': _shuffleQuestions,
          'timeLimit': _timeLimit,
          'allowRetake': _allowRetake,
          'totalPoints': totalPoints,
        },
        createdBy: user.uid,
        createdAt: widget.quizId == null ? now : DateTime.now(),
        updatedAt: now,
        isPublished: publish,
        isQuiz: true,
        isDeleted: false,
      );

      if (widget.quizId == null) {
        final docRef = await FirebaseFirestore.instance
            .collection('forms')
            .add(formData.toJson());
        setState(() {
          _isPublished = publish;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(publish ? 'Quiz published successfully!' : 'Quiz saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pop(docRef.id);
      } else {
        await FirebaseFirestore.instance
            .collection('forms')
            .doc(widget.quizId)
            .update(formData.toJson());
        setState(() {
          _isPublished = publish;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(publish ? 'Quiz published successfully!' : 'Quiz updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving quiz: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _showQuizShareDialog(String quizId, String title, bool justPublished) async {
    if (quizId.isEmpty) return;
    final link = _buildQuizLink(quizId);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(justPublished ? 'Quiz published' : 'Share quiz'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(data: link, size: 180),
              SizedBox(height: 12),
              SelectableText(link, style: TextStyle(fontSize: 12)),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: link));
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Link copied to clipboard')),
                    );
                  },
                  icon: Icon(Icons.copy),
                  label: Text('Copy link'),
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isPublished ? Icons.check_circle : Icons.info_outline, color: _isPublished ? Colors.green : Colors.orange, size: 18),
                  SizedBox(width: 6),
                  Text(_isPublished ? 'Published' : 'Draft', style: TextStyle(fontWeight: FontWeight.w500, color: _isPublished ? Colors.green : Colors.orange)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
        ],
      ),
    );
  }
  
  String _buildQuizLink(String quizId) {
    if (kIsWeb) {
      final origin = html.window.location.origin;
      return '$origin/quizzes/$quizId';
    }
    return 'https://yourdomain.com/quizzes/$quizId';
  }

  void _showTimeLimitDialog() {
    showDialog(
      context: context,
      builder: (context) {
        int tempTimeLimit = _timeLimit;
        return AlertDialog(
          title: Text('Set Time Limit'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Enter time limit in minutes (0 = no limit):'),
              SizedBox(height: 16),
              TextFormField(
                initialValue: _timeLimit.toString(),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  tempTimeLimit = int.tryParse(value) ?? 0;
                },
                decoration: InputDecoration(
                  labelText: 'Minutes',
                  border: OutlineInputBorder(),
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
              onPressed: () {
                setState(() {
                  _timeLimit = tempTimeLimit;
                });
                Navigator.pop(context);
                Navigator.pop(context);
                _showQuizSettings();
              },
              child: Text('Set'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: Text('Loading Quiz...'),
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
        ),
        body: Center(child: CircularProgressIndicator(color: colorScheme.primary)),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildEnhancedAppBar(context),
      body: ResponsiveWidget(
        mobile: _buildMobileLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
      floatingActionButton: Responsive.isMobile(context)
          ? _buildEnhancedFAB(context)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  PreferredSizeWidget _buildEnhancedAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.quizId == null ? 'Create Quiz' : 'Edit Quiz',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          if (_questions.isNotEmpty)
            Text(
              '${_questions.length} question${_questions.length == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
        ],
      ),
      backgroundColor: colorScheme.surface,
      elevation: 0,
      scrolledUnderElevation: 2,
      actions: _buildAppBarActions(context),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return [
      // Settings Button
      IconButton(
        onPressed: _showQuizSettings,
        icon: Icon(Icons.settings_outlined),
        tooltip: 'Quiz Settings',
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
        ),
      ),
      
      // Preview/Share Button
      IconButton(
        onPressed: () => _showQuizShareDialog(widget.quizId ?? '', _quizTitleController.text.trim(), false),
        icon: Icon(Icons.visibility_outlined),
        tooltip: 'Preview Quiz',
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
        ),
      ),
      
      // Save Button
      TextButton.icon(
        onPressed: _isSaving ? null : () => _saveQuiz(),
        icon: Icon(Icons.save_outlined, size: 16),
        label: Text('Save'),
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
        ),
      ),
      
      // Publish Button with green color
      Container(
        margin: EdgeInsets.only(right: 16, left: 8),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : () => _saveQuiz(publish: true),
            icon: _isSaving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.rocket_launch, size: 16),
            label: Text(_isSaving ? 'Publishing...' : 'Publish'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF34A853), // Green color
              foregroundColor: Colors.white,
              elevation: _isSaving ? 0 : 2,
              shadowColor: Color(0xFF34A853).withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildMobileLayout(BuildContext context) { return _buildEnhancedQuizBuilder(context); }

  Widget _buildDesktopLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(children: [
      Expanded(flex: 3, child: _buildEnhancedQuizBuilder(context)),
      Container(width: Responsive.getSidebarWidth(context), decoration: BoxDecoration(color: colorScheme.surface, border: Border(left: BorderSide(color: colorScheme.outline.withOpacity(0.1), width: 1))), child: _buildEnhancedQuestionTypesSidebar(context)),
    ]);
  }

  Widget _buildEnhancedFAB(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: FloatingActionButton.extended(
            onPressed: () => _showQuestionTypesBottomSheet(),
            backgroundColor: Color(0xFF34A853), // Green color
            foregroundColor: Colors.white,
            elevation: 6,
            heroTag: "addQuizQuestion",
            icon: AnimatedRotation(
              duration: Duration(milliseconds: 300),
              turns: value * 0.5,
              child: Icon(Icons.add),
            ),
            label: Text(
              'Add Question',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      margin: EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(color: Color(0xFF34A853).withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.quiz_outlined, size: 48, color: Color(0xFF34A853)),
          ),
          SizedBox(height: 24),
          Text('Start building your quiz', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text(Responsive.isMobile(context) ? 'Tap the + button to add your first question' : 'Choose a question type from the sidebar to get started', style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildEnhancedQuizHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: Responsive.paddingWhen(
        context,
        mobile: EdgeInsets.all(20),
        desktop: EdgeInsets.all(28),
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.08),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF34A853).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.quiz_outlined, color: Color(0xFF34A853), size: 16),
                    SizedBox(width: 6),
                    Text('Quiz', style: theme.textTheme.labelSmall?.copyWith(color: Color(0xFF34A853), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Spacer(),
              if (_questions.isNotEmpty)
                Text(
                  '${_questions.length} Questions • ${_questions.fold(0, (sum, q) => sum + (q.points ?? 1))} Points',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.6)),
                ),
            ],
          ),
          SizedBox(height: 16),
          TextField(
            controller: _quizTitleController,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: 'Untitled Quiz',
              border: InputBorder.none,
              hintStyle: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.4),
                fontWeight: FontWeight.bold,
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _quizDescriptionController,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
            maxLines: null,
            decoration: InputDecoration(
              hintText: 'Add a short description for this quiz (optional)',
              border: InputBorder.none,
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedQuizBuilder(BuildContext context) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            margin: Responsive.paddingWhen(
              context,
              mobile: EdgeInsets.all(16),
              desktop: EdgeInsets.all(24),
            ),
            child: _buildEnhancedQuizHeader(context),
          ),
        ),
        _questions.isEmpty
            ? SliverToBoxAdapter(child: _buildEmptyState(context))
            : SliverList.builder(
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final question = _questions[index];
                  return Container(
                    margin: EdgeInsets.only(
                      left: Responsive.valueWhen(context, mobile: 16, desktop: 24),
                      right: Responsive.valueWhen(context, mobile: 16, desktop: 24),
                      bottom: 16,
                    ),
                    child: Material(
                      elevation: _selectedQuestionId == question.id ? 6 : 2,
                      shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      child: QuizQuestionWidget(
                        key: ValueKey(question.id),
                        question: question,
                        questionNumber: index + 1,
                        isSelected: _selectedQuestionId == question.id,
                        onTap: () => setState(() => _selectedQuestionId = question.id),
                        onUpdate: _updateQuestion,
                        onDelete: () => _deleteQuestion(question.id),
                        onDuplicate: () => _duplicateQuestion(question.id),
                      ),
                    ),
                  );
                },
              ),
        SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildEnhancedQuestionTypesSidebar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final quizQuestionTypes = [
      QuestionType(type: 'multiple_choice', label: 'Multiple Choice', icon: Icons.radio_button_checked, description: 'Choose one option'),
      QuestionType(type: 'true_false', label: 'True/False', icon: Icons.check_circle_outline, description: 'True or false question'),
      QuestionType(type: 'short_answer', label: 'Short Answer', icon: Icons.short_text, description: 'Single line input'),
      QuestionType(type: 'paragraph', label: 'Paragraph', icon: Icons.subject, description: 'Multi-line input'),
      QuestionType(type: 'checkboxes', label: 'Checkboxes', icon: Icons.check_box, description: 'Choose multiple'),
      QuestionType(type: 'dropdown', label: 'Dropdown', icon: Icons.arrow_drop_down_circle, description: 'Select option'),
      QuestionType(type: 'email', label: 'Email', icon: Icons.email, description: 'Email address'),
      QuestionType(type: 'number', label: 'Number', icon: Icons.numbers, description: 'Numeric input'),
      QuestionType(type: 'date', label: 'Date', icon: Icons.calendar_today, description: 'Date picker'),
      QuestionType(type: 'time', label: 'Time', icon: Icons.access_time, description: 'Time picker'),
      QuestionType(type: 'rating', label: 'Rating', icon: Icons.star, description: 'Rating scale'),
    ];

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: colorScheme.outline.withOpacity(0.1)),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF34A853).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.add_circle_outline, color: Color(0xFF34A853), size: 20),
              ),
              SizedBox(width: 12),
              Text('Add Question', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              _buildQuestionTypeCategory(context, 'Core', quizQuestionTypes.take(3).toList()),
              SizedBox(height: 16),
              _buildQuestionTypeCategory(context, 'Text', quizQuestionTypes.where((e) => ['short_answer','paragraph','email','number'].contains(e.type)).toList()),
              SizedBox(height: 16),
              _buildQuestionTypeCategory(context, 'Choice & Interactive', quizQuestionTypes.where((e) => ['multiple_choice','checkboxes','dropdown','rating'].contains(e.type)).toList()),
              SizedBox(height: 16),
              _buildQuestionTypeCategory(context, 'Date & Time', quizQuestionTypes.where((e) => ['date','time'].contains(e.type)).toList()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionTypeCategory(
    BuildContext context,
    String title,
    List<QuestionType> items,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.7),
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: 8),
        ...items.map((item) => _buildEnhancedQuestionTypeItem(
          context,
          icon: item.icon,
          label: item.label,
          description: item.description,
          type: item.type,
        )),
      ],
    );
  }
  
  Widget _buildEnhancedQuestionTypeItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required String type,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _addQuizQuestion(type),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
              ),
              color: colorScheme.surface,
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF34A853).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Color(0xFF34A853),
                    size: 18,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.add,
                  color: Color(0xFF34A853).withOpacity(0.6),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showQuestionTypesBottomSheet() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF34A853).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add_circle_outline, color: Color(0xFF34A853), size: 20),
                  ),
                  SizedBox(width: 12),
                  Text('Add Question', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                  Spacer(),
                  IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close), style: IconButton.styleFrom(foregroundColor: colorScheme.onSurface.withOpacity(0.6))),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _buildEnhancedQuestionTypeGridItem(context, icon: Icons.radio_button_checked, label: 'Multiple Choice', description: 'Choose one', type: 'multiple_choice', gradient: LinearGradient(colors: [Colors.purple.shade400, Colors.purple.shade600])),
                    _buildEnhancedQuestionTypeGridItem(context, icon: Icons.check_circle_outline, label: 'True/False', description: 'Two options', type: 'true_false', gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade600])),
                    _buildEnhancedQuestionTypeGridItem(context, icon: Icons.short_text, label: 'Short Answer', description: 'Single line', type: 'short_answer', gradient: LinearGradient(colors: [Colors.blue.shade400, Colors.blue.shade600])),
                    _buildEnhancedQuestionTypeGridItem(context, icon: Icons.subject, label: 'Paragraph', description: 'Multi-line', type: 'paragraph', gradient: LinearGradient(colors: [Colors.indigo.shade400, Colors.indigo.shade600])),
                    _buildEnhancedQuestionTypeGridItem(context, icon: Icons.check_box, label: 'Checkboxes', description: 'Choose multiple', type: 'checkboxes', gradient: LinearGradient(colors: [Colors.orange.shade400, Colors.orange.shade600])),
                    _buildEnhancedQuestionTypeGridItem(context, icon: Icons.arrow_drop_down_circle, label: 'Dropdown', description: 'Select option', type: 'dropdown', gradient: LinearGradient(colors: [Colors.teal.shade400, Colors.teal.shade600])),
                    _buildEnhancedQuestionTypeGridItem(context, icon: Icons.email, label: 'Email', description: 'Email address', type: 'email', gradient: LinearGradient(colors: [Colors.indigoAccent.shade400, Colors.indigoAccent.shade700])),
                    _buildEnhancedQuestionTypeGridItem(context, icon: Icons.numbers, label: 'Number', description: 'Numeric', type: 'number', gradient: LinearGradient(colors: [Colors.cyan.shade400, Colors.cyan.shade600])),
                    _buildEnhancedQuestionTypeGridItem(context, icon: Icons.calendar_today, label: 'Date', description: 'Date picker', type: 'date', gradient: LinearGradient(colors: [Colors.pink.shade400, Colors.pink.shade600])),
                    _buildEnhancedQuestionTypeGridItem(context, icon: Icons.access_time, label: 'Time', description: 'Time picker', type: 'time', gradient: LinearGradient(colors: [Colors.amber.shade400, Colors.amber.shade600])),
                    _buildEnhancedQuestionTypeGridItem(context, icon: Icons.star, label: 'Rating', description: 'Rating scale', type: 'rating', gradient: LinearGradient(colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600])),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedQuestionTypeGridItem(BuildContext context, {required IconData icon, required String label, required String description, required String type, required LinearGradient gradient}) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () { Navigator.pop(context); _addQuizQuestion(type); },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: gradient.colors.first.withOpacity(0.3), blurRadius: 8, offset: Offset(0,4)),
            ],
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              SizedBox(height: 12),
              Text(label, style: theme.textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
              SizedBox(height: 4),
              Text(description, style: theme.textTheme.bodySmall?.copyWith(color: Colors.white.withOpacity(0.85), fontSize: 11), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuizSettings() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(color: colorScheme.shadow.withOpacity(0.1), blurRadius: 20, offset: Offset(0,-4)),
          ],
        ),
        child: Column(
          children: [
            Container(margin: EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: colorScheme.onSurface.withOpacity(0.2), borderRadius: BorderRadius.circular(2))),
            Container(
              padding: EdgeInsets.all(20),
              child: Row(children: [
                Icon(Icons.settings_outlined, color: Color(0xFF34A853)),
                SizedBox(width: 12),
                Text('Quiz Settings', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
                Spacer(),
                IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close), style: IconButton.styleFrom(foregroundColor: colorScheme.onSurface.withOpacity(0.6))),
              ]),
            ),
            Expanded(
              child: ListView(padding: EdgeInsets.symmetric(horizontal: 20), children: [
                _buildSettingsItem(context, icon: Icons.emoji_events_outlined, title: 'Show score at end', subtitle: 'Display final score to students', value: _showScoreAtEnd, onChanged: (v){setState(()=>_showScoreAtEnd=v);} ),
                _buildSettingsItem(context, icon: Icons.shuffle, title: 'Shuffle questions', subtitle: 'Randomize question order', value: _shuffleQuestions, onChanged: (v){setState(()=>_shuffleQuestions=v);} ),
                _buildSettingsItem(context, icon: Icons.autorenew, title: 'Allow retake', subtitle: 'Students can retake the quiz', value: _allowRetake, onChanged: (v){setState(()=>_allowRetake=v);} ),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: Container(padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Color(0xFF34A853).withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Icon(Icons.schedule, color: Color(0xFF34A853), size: 20)),
                  title: Text('Time limit', style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
                  subtitle: Text(_timeLimit == 0 ? 'No time limit' : '$_timeLimit minutes', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface.withOpacity(0.6))),
                  trailing: IconButton(icon: Icon(Icons.edit), onPressed: () => _showTimeLimitDialog()),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 8),
        secondary: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Color(0xFF34A853),
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Color(0xFF34A853),
      ),
    );
  }

  @override
  void dispose() {
    _quizTitleController.dispose();
    _quizDescriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
