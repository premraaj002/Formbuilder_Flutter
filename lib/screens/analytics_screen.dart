import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/analytics_models.dart';
import '../widgets/analytics_charts.dart';
import '../utils/responsive.dart';
import '../services/excel_export_service.dart';
import 'form_detail_analytics_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = false;
  List<FormAnalytics> _formAnalytics = [];
  String _selectedChartType = 'pie'; // 'pie' or 'bar'

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      // Load all non-deleted forms/quizzes for user
      final formsSnap = await FirebaseFirestore.instance
          .collection('forms')
          .where('createdBy', isEqualTo: user.uid)
          .where('isDeleted', isEqualTo: false)
          .get();

      final List<FormAnalytics> results = [];
      
      for (final form in formsSnap.docs) {
        final formData = form.data();
        final title = (formData['title'] ?? 'Untitled').toString();
        final List questions = (formData['questions'] as List?) ?? [];
        final bool isQuiz = formData['isQuiz'] == true;

        // Fetch from the correct collection
        final String collectionName = isQuiz ? 'quiz_responses' : 'responses';
        final String formIdField = isQuiz ? 'quizId' : 'formId';
        final String ownerIdField = isQuiz ? 'quizOwnerId' : 'formOwnerId';

        final responsesSnap = await FirebaseFirestore.instance
            .collection(collectionName)
            .where(formIdField, isEqualTo: form.id)
            .where(ownerIdField, isEqualTo: user.uid)
            .where('isDraft', isEqualTo: false)
            .get();

        final int responseCount = responsesSnap.size;
        final Map<String, double> numericAverages = {};
        final List<QuestionAnalytics> questionAnalytics = [];
        
        // Quiz scoring variables
        double totalScoreSum = 0;
        double? highestScore;
        double? lowestScore;

        // Process quiz scores
        if (isQuiz && responsesSnap.docs.isNotEmpty) {
          for (final r in responsesSnap.docs) {
            final rData = r.data();
            final score = (rData['score'] as num?)?.toDouble() ?? 0.0;
            totalScoreSum += score;
            
            if (highestScore == null || score > highestScore) highestScore = score;
            if (lowestScore == null || score < lowestScore) lowestScore = score;
          }
        }

        if (questions.isNotEmpty && responsesSnap.docs.isNotEmpty) {
          for (final q in questions) {
            final Map<String, dynamic> qMap = Map<String, dynamic>.from(q as Map);
            final String qType = (qMap['type'] ?? '').toString();
            final String qTitle = (qMap['title'] ?? '').toString();
            final String qId = (qMap['id'] ?? '').toString();

            // Process rating questions for charts
            if (qType == 'rating' || qType == 'number') {
              double sum = 0;
              int count = 0;
              Map<String, int> responseCounts = {};

              for (final r in responsesSnap.docs) {
                final rData = r.data();
                final answers = (rData['answers'] as Map?) ?? {};
                final value = answers[qId] ?? answers[qTitle];
                
                if (value != null) {
                  final num? n = value is num ? value : num.tryParse(value.toString());
                  if (n != null) {
                    sum += n.toDouble();
                    count += 1;

                    // Count occurrences for rating distribution
                    if (qType == 'rating') {
                      final ratingKey = n.round().toString();
                      responseCounts[ratingKey] = (responseCounts[ratingKey] ?? 0) + 1;
                    }
                  }
                }
              }

              if (count > 0) {
                final average = sum / count;
                numericAverages[qTitle.isNotEmpty ? qTitle : qId] = average;

                if (qType == 'rating') {
                  questionAnalytics.add(QuestionAnalytics(
                    questionId: qId,
                    questionTitle: qTitle.isNotEmpty ? qTitle : 'Rating Question',
                    questionType: qType,
                    responseCounts: responseCounts,
                    average: average,
                    totalResponses: count,
                  ));
                }
              }
            }
          }
        }

        results.add(FormAnalytics(
          formId: form.id,
          title: title,
          responseCount: responseCount,
          numericAverages: numericAverages,
          questionAnalytics: questionAnalytics,
          isQuiz: isQuiz,
          averageScore: responseCount > 0 ? totalScoreSum / responseCount : null,
          highestScore: highestScore,
          lowestScore: lowestScore,
        ));
      }

      if (mounted) {
        setState(() {
          _formAnalytics = results;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Form Analytics',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 2,
        actions: [
          // Chart type selector
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'pie',
                  icon: Icon(Icons.pie_chart, size: 16),
                  label: Text('Pie'),
                ),
                ButtonSegment(
                  value: 'bar',
                  icon: Icon(Icons.bar_chart, size: 16),
                  label: Text('Bar'),
                ),
              ],
              selected: {_selectedChartType},
              onSelectionChanged: (selection) {
                setState(() {
                  _selectedChartType = selection.first;
                });
              },
              style: SegmentedButton.styleFrom(
                backgroundColor: colorScheme.surfaceVariant.withOpacity(0.3),
                foregroundColor: colorScheme.onSurface,
                selectedBackgroundColor: colorScheme.primary,
                selectedForegroundColor: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading 
          ? _buildLoadingState() 
          : _formAnalytics.isEmpty 
              ? _buildEmptyState() 
              : _buildAnalyticsList(),
    );
  }

  Widget _buildLoadingState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 800),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.5 + (0.5 * value.clamp(0.0, 1.0)),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 24),
          Text(
            'Loading analytics...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.5 + (0.5 * value.clamp(0.0, 1.0)),
                  child: Opacity(
                    opacity: value.clamp(0.0, 1.0),
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.analytics_outlined,
                        size: 64,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              'No analytics data available',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Create forms with rating questions and collect responses to see analytics.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsList() {
    return CustomScrollView(
      slivers: [
        // Summary header
        SliverToBoxAdapter(
          child: _buildSummaryHeader(),
        ),

        // Analytics cards
        SliverPadding(
          padding: Responsive.paddingWhen(
            context,
            mobile: const EdgeInsets.all(16),
            desktop: const EdgeInsets.all(24),
          ),
          sliver: MediaQuery.of(context).size.width > 768
              ? _buildDesktopLayout(_formAnalytics)
              : _buildMobileLayout(_formAnalytics),
        ),

        // Bottom spacing
        const SliverToBoxAdapter(
          child: SizedBox(height: 32),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final totalForms = _formAnalytics.length;
    final formsWithRatings = _formAnalytics.where((f) => f.questionAnalytics.isNotEmpty).length;
    final totalRatingQuestions = _formAnalytics
        .expand((f) => f.questionAnalytics)
        .length;
    final totalResponses = _formAnalytics
        .map((f) => f.responseCount)
        .fold<int>(0, (sum, count) => sum + count.toInt());

    return Container(
      margin: Responsive.paddingWhen(
        context,
        mobile: const EdgeInsets.all(16),
        desktop: const EdgeInsets.all(24),
      ),
      child: AnalyticsCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics Overview',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Responsive.isDesktop(context)
                ? Row(
                    children: [
                      Expanded(child: _buildSummaryStat(context, 'Total Forms', totalForms.toString(), Icons.description_outlined)),
                      Expanded(child: _buildSummaryStat(context, 'Forms with Ratings', formsWithRatings.toString(), Icons.star_outline)),
                      Expanded(child: _buildSummaryStat(context, 'Rating Questions', totalRatingQuestions.toString(), Icons.quiz_outlined)),
                      Expanded(child: _buildSummaryStat(context, 'Total Responses', totalResponses.toString(), Icons.people_outline)),
                    ],
                  )
                : Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildSummaryStat(context, 'Total Forms', totalForms.toString(), Icons.description_outlined)),
                          Expanded(child: _buildSummaryStat(context, 'Forms with Ratings', formsWithRatings.toString(), Icons.star_outline)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildSummaryStat(context, 'Rating Questions', totalRatingQuestions.toString(), Icons.quiz_outlined)),
                          Expanded(child: _buildSummaryStat(context, 'Total Responses', totalResponses.toString(), Icons.people_outline)),
                        ],
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout(List<FormAnalytics> forms) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2; // Default 2 columns
    
    // Adjust columns based on screen width
    if (screenWidth > 1200) {
      crossAxisCount = 3; // 3 columns on very wide screens
    } else if (screenWidth < 900) {
      crossAxisCount = 1; // 1 column on smaller screens
    }
    
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: crossAxisCount == 1 ? 2.5 : 1.3, // Adjust ratio based on columns
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final form = forms[index];
          return _buildFormAnalyticsCard(form);
        },
        childCount: forms.length,
      ),
    );
  }

  Widget _buildMobileLayout(List<FormAnalytics> forms) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final form = forms[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600), // Limit card width on mobile
                child: _buildFormAnalyticsCard(form),
              ),
            ),
          );
        },
        childCount: forms.length,
      ),
    );
  }

  Widget _buildFormAnalyticsCard(FormAnalytics form) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.description_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      form.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      form.isQuiz 
                        ? '${form.responseCount} responses • Quiz'
                        : '${form.responseCount} responses • ${form.questionAnalytics.length} rating questions',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              // Action buttons
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
                tooltip: 'More actions',
                onSelected: (value) async {
                  if (value == 'export') {
                    await ExcelExportService.exportFormToExcel(
                      formId: form.formId,
                      formTitle: form.title,
                      context: context,
                      showCharts: true,
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(
                          Icons.download_outlined,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text('Export to Excel'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Form statistics preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Column(
              children: [
                if (form.isQuiz) ...[
                  Row(
                    children: [
                      Icon(Icons.analytics_outlined, color: Colors.blue[600], size: 20),
                      const SizedBox(width: 8),
                      Text('Avg Score', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Text('${form.averageScore?.toStringAsFixed(1) ?? '0'}%', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue[600])),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem(context, 'Highest', '${form.highestScore?.toStringAsFixed(0) ?? '0'}%', Icons.trending_up),
                      _buildStatItem(context, 'Lowest', '${form.lowestScore?.toStringAsFixed(0) ?? '0'}%', Icons.trending_down),
                    ],
                  ),
                ] else ...[
                  // Average rating display for forms
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: Colors.orange[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Average Rating',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _getFormAverageRating(form),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[600],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Response count and questions summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem(
                        context,
                        'Questions',
                        form.questionAnalytics.length.toString(),
                        Icons.quiz_outlined,
                      ),
                      _buildStatItem(
                        context,
                        'Responses',
                        form.responseCount.toString(),
                        Icons.people_outlined,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Navigation button - always at the bottom
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                print('Navigate to form analytics: ${form.title}');
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => FormDetailAnalyticsScreen(
                      formId: form.formId,
                      formTitle: form.title,
                    ),
                  ),
                );
              },
              icon: Icon(
                Icons.analytics_outlined,
                size: 18,
              ),
              label: Text(
                'View Details',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFormAverageRating(FormAnalytics form) {
    if (form.questionAnalytics.isEmpty) {
      return 'N/A';
    }

    // Calculate average for rating questions only
    final averages = form.questionAnalytics
        .where((q) => q.questionType == 'rating' && q.average != null)
        .map((q) => q.average!)
        .toList();

    if (averages.isEmpty) return 'N/A';

    final overall = averages.reduce((a, b) => a + b) / averages.length;
    return overall.toStringAsFixed(1);
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNoRatingQuestionsState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_border_outlined,
              size: 64,
              color: colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No rating questions found',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Add rating-type questions to your forms to see visual analytics here.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
