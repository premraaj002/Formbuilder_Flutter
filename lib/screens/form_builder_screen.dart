import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/form_models.dart';
import '../models/template_models.dart';
import '../widgets/question_widgets.dart';
import '../utils/responsive.dart';
import 'dart:math';

class FormBuilderScreen extends StatefulWidget {
  final String? formId; // null for new form, id for editing
  final FormTemplate? template; // Template to initialize form with

  const FormBuilderScreen({Key? key, this.formId, this.template}) : super(key: key);

  @override
  _FormBuilderScreenState createState() => _FormBuilderScreenState();
}

class _FormBuilderScreenState extends State<FormBuilderScreen> {
  final _formTitleController = TextEditingController();
  final _formDescriptionController = TextEditingController();
  final _scrollController = ScrollController();
  
  List<FormQuestion> _questions = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _selectedQuestionId;

  @override
  void initState() {
    super.initState();
    if (widget.formId != null) {
      _loadForm();
    } else {
      _initializeForm();
    }
  }

  void _initializeForm() {
    if (widget.template != null) {
      // Initialize with template
      _formTitleController.text = widget.template!.name;
      _formDescriptionController.text = widget.template!.description;
      
      // Deep copy template questions and assign new IDs
      _questions = widget.template!.questions.map((templateQuestion) {
        return FormQuestion(
          id: _generateQuestionId(),
          type: templateQuestion.type,
          title: templateQuestion.title,
          description: templateQuestion.description,
          required: templateQuestion.required,
          options: templateQuestion.options?.toList(),
          settings: templateQuestion.settings != null 
              ? Map<String, dynamic>.from(templateQuestion.settings!)
              : null,
          order: templateQuestion.order,
          isQuizQuestion: templateQuestion.isQuizQuestion,
          correctAnswer: templateQuestion.correctAnswer,
          correctAnswers: templateQuestion.correctAnswers?.toList(),
          points: templateQuestion.points,
        );
      }).toList();
      
      setState(() {});
    } else {
      // Initialize blank form
      _formTitleController.text = 'Untitled Form';
    }
  }

  Future<void> _loadForm() async {
    setState(() => _isLoading = true);
    try {
      // Load form from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('forms')
          .doc(widget.formId)
          .get();
      
      if (doc.exists) {
        final formData = FormData.fromJson(doc.data()!);
        _formTitleController.text = formData.title;
        _formDescriptionController.text = formData.description ?? '';
        _questions = formData.questions;
        setState(() {});
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading form: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _generateQuestionId() {
    return 'q_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  void _addQuestion(String type) {
    final newQuestion = FormQuestion(
      id: _generateQuestionId(),
      type: type,
      title: _getDefaultQuestionTitle(type),
      required: false,
      order: _questions.length,
      options: _needsOptions(type) ? ['Option 1'] : null,
    );

    setState(() {
      _questions.add(newQuestion);
      _selectedQuestionId = newQuestion.id;
    });

    // Scroll to new question
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
      default:
        return 'Untitled Question';
    }
  }

  bool _needsOptions(String type) {
    return ['multiple_choice', 'checkboxes', 'dropdown'].contains(type);
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
      // Reorder questions
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
    );

    setState(() {
      final insertIndex = originalQuestion.order + 1;
      _questions.insert(insertIndex, duplicatedQuestion);
      // Reorder subsequent questions
      for (int i = insertIndex + 1; i < _questions.length; i++) {
        _questions[i] = _questions[i].copyWith(order: i);
      }
    });
  }

  void _reorderQuestions(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final question = _questions.removeAt(oldIndex);
      _questions.insert(newIndex, question);
      // Update order for all questions
      for (int i = 0; i < _questions.length; i++) {
        _questions[i] = _questions[i].copyWith(order: i);
      }
    });
  }

  Future<void> _saveForm({bool publish = false}) async {
    if (_formTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a form title')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final now = DateTime.now();
      
      final formData = FormData(
        id: widget.formId,
        title: _formTitleController.text.trim(),
        description: _formDescriptionController.text.trim(),
        questions: _questions,
        quizSettings: null, // Forms (not quizzes) don't have quiz settings
        createdBy: user.uid,
        createdAt: widget.formId == null ? now : DateTime.now(),
        updatedAt: now,
        isPublished: publish,
      );

      if (widget.formId == null) {
        // Create new form
        final docRef = await FirebaseFirestore.instance
            .collection('forms')
            .add(formData.toJson());
        
        _showSuccessSnackBar(
          context,
          publish ? 'Form published successfully!' : 'Form saved successfully!',
          publish ? Icons.rocket_launch : Icons.save,
        );
        
        // Navigate back with form ID
        Navigator.of(context).pop(docRef.id);
      } else {
        // Update existing form
        await FirebaseFirestore.instance
            .collection('forms')
            .doc(widget.formId)
            .update(formData.toJson());
        
        _showSuccessSnackBar(
          context,
          publish ? 'Form published successfully!' : 'Form updated successfully!',
          publish ? Icons.rocket_launch : Icons.save,
        );
        
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving form: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _previewForm() {
    // TODO: Navigate to form preview screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Form preview coming soon!')),
    );
  }
  
  void _showFormSettings(BuildContext context) {
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
            BoxShadow(
              color: colorScheme.shadow.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.settings_outlined,
                    color: colorScheme.primary,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Form Settings',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                    style: IconButton.styleFrom(
                      foregroundColor: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            
            // Settings Options
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildSettingsItem(
                    context,
                    icon: Icons.email_outlined,
                    title: 'Collect Email Addresses',
                    subtitle: 'Require respondents to provide their email',
                    value: true,
                    onChanged: (value) {},
                  ),
                  _buildSettingsItem(
                    context,
                    icon: Icons.repeat,
                    title: 'Allow Multiple Responses',
                    subtitle: 'Let people submit more than one response',
                    value: true,
                    onChanged: (value) {},
                  ),
                  _buildSettingsItem(
                    context,
                    icon: Icons.linear_scale,
                    title: 'Show Progress Bar',
                    subtitle: 'Display completion progress to respondents',
                    value: true,
                    onChanged: (value) {},
                  ),
                  _buildSettingsItem(
                    context,
                    icon: Icons.shuffle,
                    title: 'Randomize Questions',
                    subtitle: 'Present questions in random order',
                    value: false,
                    onChanged: (value) {},
                  ),
                  _buildSettingsItem(
                    context,
                    icon: Icons.schedule,
                    title: 'Set Response Deadline',
                    subtitle: 'Stop accepting responses after a date',
                    value: false,
                    onChanged: (value) {},
                  ),
                ],
              ),
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
            color: colorScheme.primary,
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
        activeColor: colorScheme.primary,
      ),
    );
  }

  @override
  void dispose() {
    _formTitleController.dispose();
    _formDescriptionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Enhanced UI Methods
  PreferredSizeWidget _buildEnhancedAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.formId == null ? 'Create Form' : 'Edit Form',
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
        onPressed: () => _showFormSettings(context),
        icon: Icon(Icons.settings_outlined),
        tooltip: 'Form Settings',
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
        ),
      ),
      
      // Preview Button
      IconButton(
        onPressed: _previewForm,
        icon: Icon(Icons.visibility_outlined),
        tooltip: 'Preview Form',
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
        ),
      ),
      
      // Save Button
      TextButton.icon(
        onPressed: _isSaving ? null : () => _saveForm(),
        icon: Icon(Icons.save_outlined, size: 16),
        label: Text('Save'),
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.onSurfaceVariant,
        ),
      ),
      
      // Publish Button
      Container(
        margin: EdgeInsets.only(right: 16, left: 8),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : () => _saveForm(publish: true),
            icon: _isSaving
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : Icon(Icons.rocket_launch, size: 16),
            label: Text(_isSaving ? 'Publishing...' : 'Publish'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              elevation: _isSaving ? 0 : 2,
              shadowColor: colorScheme.primary.withOpacity(0.3),
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

  Widget _buildEnhancedFAB(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: FloatingActionButton.extended(
            onPressed: () => _showQuestionTypesBottomSheet(),
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            elevation: 6,
            heroTag: "addQuestion",
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

  Widget _buildMobileLayout(BuildContext context) {
    return _buildEnhancedFormBuilder(context);
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      children: [
        // Main Form Builder
        Expanded(
          flex: 3,
          child: _buildEnhancedFormBuilder(context),
        ),
        
        // Enhanced Sidebar
        Container(
          width: Responsive.getSidebarWidth(context),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              left: BorderSide(
                color: colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
          ),
          child: _buildEnhancedQuestionTypesSidebar(context),
        ),
      ],
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
          title: Text('Loading Form...'),
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 800),
                curve: Curves.easeOut,
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.5 + (0.5 * value),
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: CircularProgressIndicator(
                          color: colorScheme.primary,
                          strokeWidth: 3,
                        ),
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 24),
              TweenAnimationBuilder<double>(
                duration: Duration(milliseconds: 1000),
                curve: Curves.easeOut,
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: Text(
                      'Loading your form...',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
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

  Widget _buildEnhancedFormBuilder(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Form Header Section
        SliverToBoxAdapter(
          child: Container(
            margin: Responsive.paddingWhen(
              context,
              mobile: EdgeInsets.all(16),
              tablet: EdgeInsets.all(20),
              desktop: EdgeInsets.all(24),
            ),
            child: _buildEnhancedFormHeader(context),
          ),
        ),
        
        // Empty State or Questions List
        _questions.isEmpty
            ? SliverToBoxAdapter(
                child: _buildEmptyState(context),
              )
            : SliverReorderableList(
                itemCount: _questions.length,
                onReorder: _reorderQuestions,
                itemBuilder: (context, index) {
                  final question = _questions[index];
                  return _buildAnimatedQuestionCard(
                    context,
                    question,
                    index,
                  );
                },
              ),
        
        // Bottom Spacing
        SliverToBoxAdapter(
          child: SizedBox(height: 100),
        ),
      ],
    );
  }

  Widget _buildEnhancedFormHeader(BuildContext context) {
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
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form Title
          Container(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: TextField(
              controller: _formTitleController,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: 'Untitled Form',
                border: InputBorder.none,
                hintStyle: theme.textTheme.headlineSmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.4),
                  fontWeight: FontWeight.bold,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
          ),
          
          SizedBox(height: 12),
          
          // Form Description
          TextField(
            controller: _formDescriptionController,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
            maxLines: null,
            decoration: InputDecoration(
              hintText: 'Add a description to help people understand your form',
              border: InputBorder.none,
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
          ),
          
          // Form Stats (if questions exist)
          if (_questions.isNotEmpty) ...[
            SizedBox(height: 16),
            Divider(color: colorScheme.outline.withOpacity(0.2)),
            SizedBox(height: 12),
            Row(
              children: [
                _buildStatChip(
                  context,
                  Icons.quiz_outlined,
                  '${_questions.length} question${_questions.length == 1 ? '' : 's'}',
                ),
                SizedBox(width: 12),
                _buildStatChip(
                  context,
                  Icons.timer_outlined,
                  '~${(_questions.length * 0.5).ceil()} min',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip(BuildContext context, IconData icon, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: colorScheme.primary,
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 40),
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 1000),
        curve: Curves.easeOutBack,
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.5 + (0.5 * value),
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 1500),
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, iconValue, child) {
                        return AnimatedRotation(
                          duration: Duration(milliseconds: 2000),
                          turns: iconValue * 0.5,
                          child: Icon(
                            Icons.quiz_outlined,
                            size: 48,
                            color: colorScheme.primary,
                          ),
                        );
                      },
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  Text(
                    'Start building your form',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  
                  SizedBox(height: 8),
                  
                  Text(
                    Responsive.isMobile(context)
                        ? 'Tap the + button to add your first question'
                        : 'Choose a question type from the sidebar to get started',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  SizedBox(height: 24),
                  
                  if (Responsive.isMobile(context))
                    TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 1200),
                      curve: Curves.elasticOut,
                      tween: Tween(begin: 0.0, end: 1.0),
                      builder: (context, buttonValue, child) {
                        return Transform.scale(
                          scale: buttonValue,
                          child: ElevatedButton.icon(
                            onPressed: () => _showQuestionTypesBottomSheet(),
                            icon: Icon(Icons.add),
                            label: Text('Add Question'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              elevation: 4,
                              shadowColor: colorScheme.primary.withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnimatedQuestionCard(BuildContext context, FormQuestion question, int index) {
    final isSelected = _selectedQuestionId == question.id;
    
    return Container(
      key: ValueKey(question.id),
      margin: EdgeInsets.only(
        left: Responsive.valueWhen(context, mobile: 16, desktop: 24),
        right: Responsive.valueWhen(context, mobile: 16, desktop: 24),
        bottom: 16,
      ),
      child: TweenAnimationBuilder<double>(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        tween: Tween(begin: 0.0, end: 1.0),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 0.8 + (0.2 * value),
            child: Opacity(
              opacity: value.clamp(0.0, 1.0),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                transform: Matrix4.identity()
                  ..translate(0.0, isSelected ? -2.0 : 0.0),
                child: Material(
                  elevation: isSelected ? 8 : 2,
                  shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  child: QuestionWidget(
                    question: question,
                    isSelected: isSelected,
                    onTap: () {
                      setState(() {
                        _selectedQuestionId = question.id;
                      });
                      // Add haptic feedback
                      _provideFeedback();
                    },
                    onUpdate: _updateQuestion,
                    onDelete: () => _deleteQuestion(question.id),
                    onDuplicate: () => _duplicateQuestion(question.id),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  void _provideFeedback() {
    // Add light haptic feedback for better UX
    // Note: You might need to add haptic_feedback package for this
    // HapticFeedback.lightImpact();
  }
  
  void _showSuccessSnackBar(BuildContext context, String message, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white70,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Widget _buildEnhancedQuestionTypesSidebar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Column(
      children: [
        // Sidebar Header
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: colorScheme.outline.withOpacity(0.1),
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.add_circle_outline,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Add Question',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        
        // Question Types List
        Expanded(
          child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              _buildQuestionTypeCategory(
                context,
                'Text Input',
                [
                  _QuestionTypeItem(
                    icon: Icons.short_text,
                    label: 'Short Answer',
                    description: 'Single line text input',
                    type: 'short_answer',
                  ),
                  _QuestionTypeItem(
                    icon: Icons.subject,
                    label: 'Paragraph',
                    description: 'Multi-line text input',
                    type: 'paragraph',
                  ),
                  _QuestionTypeItem(
                    icon: Icons.email,
                    label: 'Email',
                    description: 'Email address input',
                    type: 'email',
                  ),
                  _QuestionTypeItem(
                    icon: Icons.numbers,
                    label: 'Number',
                    description: 'Numeric input',
                    type: 'number',
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              _buildQuestionTypeCategory(
                context,
                'Choice Questions',
                [
                  _QuestionTypeItem(
                    icon: Icons.radio_button_checked,
                    label: 'Multiple Choice',
                    description: 'Choose one option',
                    type: 'multiple_choice',
                  ),
                  _QuestionTypeItem(
                    icon: Icons.check_box,
                    label: 'Checkboxes',
                    description: 'Choose multiple options',
                    type: 'checkboxes',
                  ),
                  _QuestionTypeItem(
                    icon: Icons.arrow_drop_down_circle,
                    label: 'Dropdown',
                    description: 'Dropdown selection',
                    type: 'dropdown',
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              _buildQuestionTypeCategory(
                context,
                'Date & Time',
                [
                  _QuestionTypeItem(
                    icon: Icons.calendar_today,
                    label: 'Date',
                    description: 'Date picker',
                    type: 'date',
                  ),
                  _QuestionTypeItem(
                    icon: Icons.access_time,
                    label: 'Time',
                    description: 'Time picker',
                    type: 'time',
                  ),
                ],
              ),
              
              SizedBox(height: 16),
              
              _buildQuestionTypeCategory(
                context,
                'Interactive',
                [
                  _QuestionTypeItem(
                    icon: Icons.star,
                    label: 'Rating',
                    description: 'Rating scale',
                    type: 'rating',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionTypeCategory(
    BuildContext context,
    String title,
    List<_QuestionTypeItem> items,
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
          onTap: () => _addQuestion(type),
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
                    color: colorScheme.primaryContainer.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: colorScheme.primary,
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
                  color: colorScheme.primary.withOpacity(0.6),
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
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.add_circle_outline,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Add Question',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                    style: IconButton.styleFrom(
                      foregroundColor: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            
            // Question Types Grid
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 1.1,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: [
                    _buildEnhancedQuestionTypeGridItem(
                      context,
                      icon: Icons.short_text,
                      label: 'Short Answer',
                      description: 'Single line text',
                      type: 'short_answer',
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade400, Colors.blue.shade600],
                      ),
                    ),
                    _buildEnhancedQuestionTypeGridItem(
                      context,
                      icon: Icons.subject,
                      label: 'Paragraph',
                      description: 'Multi-line text',
                      type: 'paragraph',
                      gradient: LinearGradient(
                        colors: [Colors.green.shade400, Colors.green.shade600],
                      ),
                    ),
                    _buildEnhancedQuestionTypeGridItem(
                      context,
                      icon: Icons.radio_button_checked,
                      label: 'Multiple Choice',
                      description: 'Choose one',
                      type: 'multiple_choice',
                      gradient: LinearGradient(
                        colors: [Colors.purple.shade400, Colors.purple.shade600],
                      ),
                    ),
                    _buildEnhancedQuestionTypeGridItem(
                      context,
                      icon: Icons.check_box,
                      label: 'Checkboxes',
                      description: 'Choose multiple',
                      type: 'checkboxes',
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade400, Colors.orange.shade600],
                      ),
                    ),
                    _buildEnhancedQuestionTypeGridItem(
                      context,
                      icon: Icons.arrow_drop_down_circle,
                      label: 'Dropdown',
                      description: 'Select option',
                      type: 'dropdown',
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade400, Colors.teal.shade600],
                      ),
                    ),
                    _buildEnhancedQuestionTypeGridItem(
                      context,
                      icon: Icons.email,
                      label: 'Email',
                      description: 'Email address',
                      type: 'email',
                      gradient: LinearGradient(
                        colors: [Colors.indigo.shade400, Colors.indigo.shade600],
                      ),
                    ),
                    _buildEnhancedQuestionTypeGridItem(
                      context,
                      icon: Icons.numbers,
                      label: 'Number',
                      description: 'Numeric input',
                      type: 'number',
                      gradient: LinearGradient(
                        colors: [Colors.cyan.shade400, Colors.cyan.shade600],
                      ),
                    ),
                    _buildEnhancedQuestionTypeGridItem(
                      context,
                      icon: Icons.calendar_today,
                      label: 'Date',
                      description: 'Date picker',
                      type: 'date',
                      gradient: LinearGradient(
                        colors: [Colors.pink.shade400, Colors.pink.shade600],
                      ),
                    ),
                    _buildEnhancedQuestionTypeGridItem(
                      context,
                      icon: Icons.access_time,
                      label: 'Time',
                      description: 'Time picker',
                      type: 'time',
                      gradient: LinearGradient(
                        colors: [Colors.amber.shade400, Colors.amber.shade600],
                      ),
                    ),
                    _buildEnhancedQuestionTypeGridItem(
                      context,
                      icon: Icons.star,
                      label: 'Rating',
                      description: 'Rating scale',
                      type: 'rating',
                      gradient: LinearGradient(
                        colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade600],
                      ),
                    ),
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

  Widget _buildEnhancedQuestionTypeGridItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
    required String type,
    required LinearGradient gradient,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _addQuestion(type);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        
                        SizedBox(height: 12),
                        
                        Text(
                          label,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        SizedBox(height: 4),
                        
                        Text(
                          description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Helper class for question type items
class _QuestionTypeItem {
  final IconData icon;
  final String label;
  final String description;
  final String type;
  
  const _QuestionTypeItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.type,
  });
}