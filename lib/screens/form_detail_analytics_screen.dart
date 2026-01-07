import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/analytics_models.dart';
import '../widgets/analytics_charts.dart';
import '../services/excel_export_service.dart';

class FormDetailAnalyticsScreen extends StatefulWidget {
  final String formId;
  final String formTitle;

  const FormDetailAnalyticsScreen({
    super.key,
    required this.formId,
    required this.formTitle,
  });

  @override
  State<FormDetailAnalyticsScreen> createState() => _FormDetailAnalyticsScreenState();
}

class _FormDetailAnalyticsScreenState extends State<FormDetailAnalyticsScreen> {
  bool _isLoading = false;
  FormAnalytics? _analytics;
  List<Map<String, dynamic>> _responses = [];
  String _selectedChartType = 'pie';

  @override
  void initState() {
    super.initState();
    _loadDetailedAnalytics();
  }

  Future<void> _loadDetailedAnalytics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      print('Loading detailed analytics for form: ${widget.formId}');
      
      // Load form data
      final formDoc = await FirebaseFirestore.instance
          .collection('forms')
          .doc(widget.formId)
          .get();

      if (!formDoc.exists) {
        print('Form document not found: ${widget.formId}');
        throw Exception('Form not found');
      }
      
      print('Form document found, loading questions...');

      final formData = formDoc.data()!;
      final List questions = (formData['questions'] as List?) ?? [];

      // Load responses
      print('Loading responses for form: ${widget.formId}, owner: ${user.uid}');
      final responsesSnap = await FirebaseFirestore.instance
          .collection('responses')
          .where('formId', isEqualTo: widget.formId)
          .where('formOwnerId', isEqualTo: user.uid)
          .where('isDraft', isEqualTo: false)
          .get();
      
      print('Found ${responsesSnap.docs.length} responses');

      final List<Map<String, dynamic>> responses = [];
      for (final doc in responsesSnap.docs) {
        final data = doc.data();
        responses.add({
          'id': doc.id,
          'userEmail': data['userEmail'] ?? 'Anonymous',
          'userName': data['userName'] ?? data['userEmail']?.split('@')[0] ?? 'Anonymous',
          'submittedAt': data['submittedAt'] as Timestamp?,
          'answers': data['answers'] ?? {},
        });
      }
      
      // Sort responses by submission date (most recent first)
      responses.sort((a, b) {
        final aTime = a['submittedAt'] as Timestamp?;
        final bTime = b['submittedAt'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime); // Descending order
      });

      // Generate analytics
      final analytics = await _generateDetailedAnalytics(
        widget.formId,
        widget.formTitle,
        formData,
        responsesSnap.docs,
        questions,
      );

      if (mounted) {
        setState(() {
          _analytics = analytics;
          _responses = responses;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<FormAnalytics> _generateDetailedAnalytics(
    String formId,
    String title,
    Map<String, dynamic> formData,
    List<QueryDocumentSnapshot> responses,
    List<dynamic> questions,
  ) async {
    final int responseCount = responses.length;
    final Map<String, double> numericAverages = {};
    final List<QuestionAnalytics> questionAnalytics = [];

    if (questions.isNotEmpty && responses.isNotEmpty) {
      for (final q in questions) {
        final Map<String, dynamic> qMap = Map<String, dynamic>.from(q as Map);
        final String qType = (qMap['type'] ?? '').toString();
        final String qTitle = (qMap['title'] ?? '').toString();
        final String qId = (qMap['id'] ?? '').toString();

        Map<String, int> responseCounts = {};
        double sum = 0;
        int count = 0;

        // Process all question types for better analytics
        for (final r in responses) {
          final rData = r.data() as Map<String, dynamic>?;
          if (rData != null) {
            final answers = (rData['answers'] as Map<String, dynamic>?) ?? <String, dynamic>{};
            final value = answers[qId] ?? answers[qTitle];

          if (value != null) {
            switch (qType) {
              case 'rating':
              case 'number':
                final num? n = value is num ? value : num.tryParse(value.toString());
                if (n != null) {
                  sum += n.toDouble();
                  count += 1;
                  final key = qType == 'rating' ? n.round().toString() : n.toString();
                  responseCounts[key] = (responseCounts[key] ?? 0) + 1;
                }
                break;
              case 'multiple_choice':
              case 'dropdown':
                final strValue = value.toString();
                if (strValue.isNotEmpty) {
                  responseCounts[strValue] = (responseCounts[strValue] ?? 0) + 1;
                  count++;
                }
                break;
              case 'checkboxes':
                if (value is List) {
                  for (final item in value) {
                    final strValue = item.toString();
                    if (strValue.isNotEmpty) {
                      responseCounts[strValue] = (responseCounts[strValue] ?? 0) + 1;
                    }
                  }
                  count++;
                } else if (value.toString().isNotEmpty) {
                  // Handle cases where checkbox value is stored as string
                  final strValue = value.toString();
                  responseCounts[strValue] = (responseCounts[strValue] ?? 0) + 1;
                  count++;
                }
                break;
              case 'true_false':
              case 'yes_no':
                final boolValue = value.toString().toLowerCase();
                if (boolValue.isNotEmpty && boolValue != 'null') {
                  responseCounts[boolValue] = (responseCounts[boolValue] ?? 0) + 1;
                  count++;
                }
                break;
              case 'text':
              case 'long_text':
              case 'email':
              default:
                // For text fields, just count non-empty responses
                if (value.toString().trim().isNotEmpty) {
                  count++;
                  // For text responses, we could add word count or character count analytics
                  responseCounts['responses'] = count;
                }
            }
          }
          }
        }

        if (count > 0) {
          double? average;
          if (qType == 'rating' || qType == 'number') {
            average = sum / count;
            numericAverages[qTitle.isNotEmpty ? qTitle : qId] = average;
          }

          // Create question analytics for all question types with responses
          questionAnalytics.add(QuestionAnalytics(
            questionId: qId,
            questionTitle: qTitle.isNotEmpty ? qTitle : 'Question ${questionAnalytics.length + 1}',
            questionType: qType,
            responseCounts: responseCounts,
            average: average,
            totalResponses: count,
          ));
        }
      }
    }

    return FormAnalytics(
      formId: formId,
      title: title,
      responseCount: responseCount,
      numericAverages: numericAverages,
      questionAnalytics: questionAnalytics,
    );
  }

  void _showResponsesDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.people, color: Colors.blue[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Form Responses',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${_responses.length} responses',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _responses.length,
                  itemBuilder: (context, index) {
                    final response = _responses[index];
                    final submittedAt = response['submittedAt'] as Timestamp?;
                    final formattedDate = submittedAt != null
                        ? '${submittedAt.toDate().day}/${submittedAt.toDate().month}/${submittedAt.toDate().year}'
                        : 'N/A';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: Text(
                            response['userName'].toString().substring(0, 1).toUpperCase(),
                            style: TextStyle(
                              color: Colors.blue[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(response['userName'] ?? 'Anonymous'),
                        subtitle: Text(response['userEmail'] ?? 'No email'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              formattedDate,
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              submittedAt != null
                                  ? '${submittedAt.toDate().hour.toString().padLeft(2, '0')}:${submittedAt.toDate().minute.toString().padLeft(2, '0')}'
                                  : '',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          _showResponseDetails(response);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showResponseDetails(Map<String, dynamic> response) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green[100],
                    child: Text(
                      response['userName'].toString().substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: Colors.green[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          response['userName'] ?? 'Anonymous',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          response['userEmail'] ?? 'No email',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 32),
              Text(
                'Response Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ..._buildAnswersList(response['answers'] as Map),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAnswersList(Map<dynamic, dynamic> answers) {
    final widgets = <Widget>[];
    
    if (_analytics?.questionAnalytics.isNotEmpty ?? false) {
      for (final question in _analytics!.questionAnalytics) {
        final answer = answers.isNotEmpty ? (answers[question.questionId] ?? answers[question.questionTitle]) : null;
        
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question.questionTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  answer?.toString() ?? 'No answer',
                  style: TextStyle(
                    fontSize: 16,
                    color: answer != null ? Colors.black87 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    
    if (widgets.isEmpty) {
      widgets.add(
        const Text(
          'No answers found',
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.formTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 2,
        actions: [
          // Chart type selector
          Container(
            margin: const EdgeInsets.only(right: 8),
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
          // Export button
          IconButton(
            onPressed: _analytics != null ? _exportToExcel : null,
            icon: const Icon(Icons.download),
            tooltip: 'Export to Excel',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _analytics == null
              ? _buildErrorState()
              : _buildAnalyticsContent(),
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
            'Loading detailed analytics...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Analyzing ${widget.formTitle}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
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
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[400],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            Text(
              'Failed to load analytics',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'We couldn\'t load the analytics for this form. This may be due to missing data or a connection issue.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _loadDetailedAnalytics,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsContent() {
    if (_analytics == null) return const SizedBox.shrink();

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Summary cards
              _buildSummaryCards(),
              const SizedBox(height: 32),
              
              // Responses section
              _buildResponsesSection(),
              const SizedBox(height: 32),
              
              // Charts section  
              if (_analytics!.questionAnalytics.where((q) => q.canBeVisualized()).isNotEmpty) ...[
                _buildChartsSection(),
              ] else ...[
                _buildNoChartsMessage(),
              ],
              
              // Bottom padding
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final isNarrow = MediaQuery.of(context).size.width < 600;
    
    if (isNarrow) {
      // Stack cards vertically on narrow screens
      return Column(
        children: [
          _buildSummaryCard(
            'Total Responses',
            _analytics!.responseCount.toString(),
            Icons.people,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Visualizable Questions',
                  _analytics!.questionAnalytics.where((q) => q.canBeVisualized()).length.toString(),
                  Icons.star,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Avg Rating',
                  _getOverallAverageRating(),
                  Icons.analytics,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // Show cards in a row on wider screens
      return Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total Responses',
              _analytics!.responseCount.toString(),
              Icons.people,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Visualizable Questions',
              _analytics!.questionAnalytics.where((q) => q.canBeVisualized()).length.toString(),
              Icons.star,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Avg Rating',
              _getOverallAverageRating(),
              Icons.analytics,
              Colors.green,
            ),
          ),
        ],
      );
    }
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsesSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Responses',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showResponsesDialog,
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${_responses.length} people have responded to this form',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            if (_responses.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Recent responses:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ...(_responses.take(3).map((response) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue[100],
                      child: Text(
                        response['userName'].toString().substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        response['userName'] ?? 'Anonymous',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      _formatDate(response['submittedAt'] as Timestamp?),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ))),
              if (_responses.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'and ${_responses.length - 3} more...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection() {
    final visualizableQuestions = _analytics!.questionAnalytics.where((q) => q.canBeVisualized()).toList();
    final isDesktop = MediaQuery.of(context).size.width > 900;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall Form Analytics
        _buildOverallAnalyticsCard(),
        const SizedBox(height: 32),
        
        // Individual Question Analytics Header
        Row(
          children: [
            Icon(Icons.quiz_outlined, color: Colors.green[600]),
            const SizedBox(width: 8),
            Text(
              'Question Analytics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Questions Grid Layout - 3 per row on desktop, 1 per row on mobile
        if (isDesktop)
          _buildDesktopQuestionGrid(visualizableQuestions)
        else
          _buildMobileQuestionList(visualizableQuestions),
      ],
    );
  }

  Widget _buildOverallAnalyticsCard() {
    if (_analytics?.questionAnalytics.isEmpty ?? true) {
      return const SizedBox.shrink();
    }

    // Create overall analytics combining all question data
    final overallAnalytics = _createOverallAnalytics();
    if (overallAnalytics == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.analytics_outlined, color: Colors.blue[600]),
                const SizedBox(width: 8),
                Text(
                  'Overall Form Analytics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Combined data from all ${_analytics!.questionAnalytics.length} questions',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              height: 320,
              width: double.infinity,
              alignment: Alignment.center,
              child: _selectedChartType == 'pie'
                  ? RatingPieChart(
                      questionAnalytics: overallAnalytics,
                      size: 280,
                    )
                  : RatingBarChart(
                      questionAnalytics: overallAnalytics,
                      height: 300,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  QuestionAnalytics? _createOverallAnalytics() {
    if (_analytics?.questionAnalytics.isEmpty ?? true) {
      return null;
    }

    final Map<String, int> combinedCounts = <String, int>{};
    double totalSum = 0;
    int totalCount = 0;
    int totalResponses = 0;

    // Combine all question analytics
    for (final question in _analytics!.questionAnalytics) {
      if (question.canBeVisualized()) {
        totalResponses += question.totalResponses;
        
        // Combine response counts
        question.responseCounts.forEach((key, count) {
          combinedCounts[key] = (combinedCounts[key] ?? 0) + count;
        });

        // For rating questions, add to average calculation
        if (question.average != null && question.questionType == 'rating') {
          totalSum += question.average! * question.totalResponses;
          totalCount += question.totalResponses;
        }
      }
    }

    if (combinedCounts.isEmpty) {
      return null;
    }

    final double? overallAverage = totalCount > 0 ? totalSum / totalCount : null;

    return QuestionAnalytics(
      questionId: 'overall',
      questionTitle: 'Overall Form Analytics',
      questionType: 'combined',
      responseCounts: combinedCounts,
      average: overallAverage,
      totalResponses: totalResponses,
    );
  }

  Widget _buildDesktopQuestionGrid(List<QuestionAnalytics> questions) {
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 3; // Default 3 columns
    double childAspectRatio = 1; // Increased to make cards shorter (more width relative to height)
    
    // Responsive column count based on screen width - all increased to reduce height
    if (screenWidth > 1400) {
      crossAxisCount = 4; // 4 columns on very wide screens
      childAspectRatio = 1.1; // More width relative to height = shorter cards
    } else if (screenWidth > 1200) {
      crossAxisCount = 3; // 3 columns on wide screens
      childAspectRatio = 1.2; // Shorter cards
    } else if (screenWidth > 900) {
      crossAxisCount = 2; // 2 columns on medium screens
      childAspectRatio = 1.3; // Even shorter cards
    } else {
      crossAxisCount = 1; // 1 column on smaller screens
      childAspectRatio = 1.4; // Shortest cards for mobile
    }
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        return _buildQuestionCard(question, isInGrid: true);
      },
    );
  }

  Widget _buildMobileQuestionList(List<QuestionAnalytics> questions) {
    return Column(
      children: questions.map((question) {
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width > 600 ? 500 : double.infinity,
              ),
              child: _buildQuestionCard(question, isInGrid: false),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuestionCard(QuestionAnalytics question, {required bool isInGrid}) {
    final chartSize = isInGrid ? 200.0 : 300.0; // Larger size to match overall analytics
    final chartHeight = isInGrid ? 220.0 : 340.0; // Proportional chart height
    final cardPadding = isInGrid ? 8.0 : 16.0; // Reasonable padding
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Question title
            Text(
              question.questionTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isInGrid ? 16 : null, // Readable size
              ),
              maxLines: 2, // Allow 2 lines for better readability
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isInGrid ? 2 : 3), // Compact spacing
            
            // Question stats
            if (question.average != null)
              Text(
                'Avg: ${question.average!.toStringAsFixed(1)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: isInGrid ? 12 : 14, // Slightly smaller for compactness
                ),
                textAlign: TextAlign.center,
              ),
            Text(
              '${question.totalResponses} responses',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: isInGrid ? 12 : 14, // Slightly smaller for compactness
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isInGrid ? 6 : 8), // Compact spacing for chart
            
            // Chart container - use different widgets for grid vs individual
            Expanded(
              child: Container(
                width: double.infinity,
                alignment: Alignment.center, // Center alignment like overall analytics
                child: _selectedChartType == 'pie'
                    ? (isInGrid 
                        ? _buildSimplePieChart(question, chartSize)
                        : RatingPieChart(
                            questionAnalytics: question,
                            size: chartSize,
                          ))
                    : RatingBarChart(
                        questionAnalytics: question,
                        height: chartHeight,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimplePieChart(QuestionAnalytics question, double size) {
    // Convert non-rating responses to chart data format
    List<RatingData> chartData;
    if (question.questionType == 'rating') {
      chartData = question.getRatingDistribution();
    } else {
      chartData = _convertToChartData(question);
    }
    
    if (chartData.isEmpty || question.totalResponses == 0) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, size: 80, color: Colors.grey[400]), // Increased by 40% (32*1.4≈45)
            const SizedBox(height: 8),
            Text(
              'No data',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 17, // Increased by 40% (12*1.4≈17)
              ),
            ),
          ],
        ),
      );
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate available space for chart and legend - make chart bigger
        final availableHeight = constraints.maxHeight;
        final legendHeight = 32.0; // Space for legend
        final spacing = 8.0; // Good spacing
        final maxChartSize = availableHeight - legendHeight - spacing;
        final chartSize = math.min(size * 1.1, maxChartSize); // Make chart 10% bigger
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Just the pie chart, no title or stats - Center it like overall analytics
            Center(
              child: SizedBox(
                width: chartSize,
                height: chartSize,
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      enabled: true,
                      mouseCursorResolver: (FlTouchEvent event, PieTouchResponse? response) {
                        if (response?.touchedSection != null) {
                          return SystemMouseCursors.click;
                        }
                        return MouseCursor.defer;
                      },
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        // Enhanced hover handling for web
                        if (pieTouchResponse != null && pieTouchResponse.touchedSection != null) {
                          // Section is being hovered/touched
                        }
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2, // Reduce spacing for better hover detection
                    centerSpaceRadius: chartSize * 0.2, // Reduce center space for more hover area
                    sections: chartData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;
                      
                      return PieChartSectionData(
                        color: Color(_getRatingColor(data.rating)),
                        value: data.count.toDouble(),
                        title: data.count > 0 ? '${data.percentage.toStringAsFixed(1)}%' : '', // Show decimal like overall
                        radius: 55.0, // Base radius
                        titleStyle: const TextStyle(
                          fontSize: 14, // Larger text like overall analytics
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        titlePositionPercentageOffset: 0.50, // Perfect visual center of pie section
                        showTitle: true,
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8), // Better spacing
            // Legend styled like overall analytics
            Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8, // Better spacing like overall analytics
                runSpacing: 4, // Better spacing
                children: chartData.where((data) => data.count > 0).map((data) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10, // Larger indicator like overall analytics
                          height: 10,
                          decoration: BoxDecoration(
                            color: Color(_getRatingColor(data.rating)),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          question.questionType == 'rating'
                              ? '${data.rating} (${data.count})' // Show count like overall analytics
                              : '${data.label} (${data.count})',
                          style: TextStyle(
                            fontSize: 12, // Larger text like overall analytics
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[300], // Better contrast
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Helper method to convert non-rating questions to chart data
  List<RatingData> _convertToChartData(QuestionAnalytics question) {
    final responseCounts = question.responseCounts;
    final totalResponses = question.totalResponses;
    
    if (totalResponses == 0) return [];
    
    final List<RatingData> chartData = [];
    int index = 1;
    
    for (final entry in responseCounts.entries) {
      final count = entry.value;
      final percentage = (count / totalResponses) * 100;
      
      chartData.add(RatingData(
        rating: index,
        count: count,
        percentage: percentage,
        label: entry.key,
      ));
      index++;
    }
    
    return chartData;
  }
  
  // Helper method to get rating colors (matching ChartColors utility)
  int _getRatingColor(int rating) {
    switch (rating) {
      case 1: return 0xFFE53E3E; // Red
      case 2: return 0xFFFF8A00; // Orange  
      case 3: return 0xFFFFC107; // Yellow
      case 4: return 0xFF38A169; // Light Green
      case 5: return 0xFF22C55E; // Bright Green (distinct from rating 4)
      default: return 0xFF718096; // Gray
    }
  }

  Widget _buildNoChartsMessage() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Chart Data Available',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This form doesn\'t contain rating or multiple choice questions that can be visualized in charts.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getOverallAverageRating() {
    if (_analytics?.questionAnalytics.isEmpty ?? true) {
      return 'N/A';
    }

    // Only calculate average for rating questions
    final averages = _analytics!.questionAnalytics
        .where((q) => q.questionType == 'rating' && q.average != null)
        .map((q) => q.average!)
        .toList();

    if (averages.isEmpty) return 'N/A';

    final overall = averages.reduce((a, b) => a + b) / averages.length;
    return overall.toStringAsFixed(2);
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _exportToExcel() async {
    if (_analytics == null) return;

    await ExcelExportService.exportFormToExcel(
      formId: widget.formId,
      formTitle: widget.formTitle,
      context: context,
      showCharts: true,
    );
  }
}
