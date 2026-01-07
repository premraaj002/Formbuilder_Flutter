import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentResponseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> responseData;
  final String responseId;

  const StudentResponseDetailScreen({
    super.key,
    required this.responseData,
    required this.responseId,
  });

  @override
  State<StudentResponseDetailScreen> createState() => _StudentResponseDetailScreenState();
}

class _StudentResponseDetailScreenState extends State<StudentResponseDetailScreen> {
  Map<String, dynamic>? formData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  Future<void> _loadFormData() async {
    try {
      final formId = widget.responseData['formId'];
      if (formId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('forms')
            .doc(formId)
            .get();
        
        if (doc.exists) {
          setState(() {
            formData = doc.data();
          });
        }
      }
    } catch (e) {
      print('Error loading form data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final submittedAt = widget.responseData['submittedAt'] as Timestamp?;
    final formTitle = widget.responseData['formTitle'] ?? 'Untitled Form';
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Response Details',
          style: TextStyle(
            color: Colors.grey[800],
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.grey[800]),
      ),
      body: isLoading 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.green[600]),
                SizedBox(height: 16),
                Text('Loading response details...'),
              ],
            ),
          )
        : SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Form title card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.assignment_turned_in,
                              color: Colors.green[700],
                              size: 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              formTitle,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Submitted on ${submittedAt?.toDate().toString().substring(0, 19) ?? 'Unknown'}',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Form description if available
                if (formData?['description'] != null && formData!['description'].isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                            SizedBox(width: 6),
                            Text(
                              'Form Description',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Text(
                          formData!['description'],
                          style: TextStyle(
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                ],

                // Your responses section
                Text(
                  'Your Responses',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                SizedBox(height: 16),

                // Response items
                ...(_buildResponseItems()),
              ],
            ),
          ),
    );
  }

  List<Widget> _buildResponseItems() {
    final answers = widget.responseData['answers'] as Map<String, dynamic>? ?? {};
    final questions = formData?['questions'] as List? ?? [];
    
    if (questions.isEmpty) {
      return [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Column(
            children: [
              Icon(Icons.help_outline, color: Colors.orange[600], size: 32),
              SizedBox(height: 8),
              Text(
                'No question data available',
                style: TextStyle(
                  color: Colors.orange[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'The original form questions could not be loaded.',
                style: TextStyle(
                  color: Colors.orange[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ];
    }

    List<Widget> responseWidgets = [];
    
    for (int i = 0; i < questions.length; i++) {
      final question = questions[i] as Map<String, dynamic>;
      final questionId = question['id']?.toString() ?? '';
      final questionTitle = question['title']?.toString() ?? question['question']?.toString() ?? '';
      final questionType = question['type']?.toString() ?? '';
      
      // Find the answer for this question
      dynamic answer = answers[questionId] ?? answers[questionTitle] ?? answers[i.toString()];
      
      responseWidgets.add(
        Container(
          margin: EdgeInsets.only(bottom: 16),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[200]!),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question number and title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          questionTitle.isNotEmpty ? questionTitle : 'Question ${i + 1}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      if (question['required'] == true)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Required',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.red[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Question type indicator
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getQuestionTypeDisplay(questionType),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Answer display
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Answer:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                        SizedBox(height: 6),
                        _buildAnswerDisplay(answer, questionType),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    
    return responseWidgets;
  }

  String _getQuestionTypeDisplay(String type) {
    switch (type.toLowerCase()) {
      case 'short_answer':
      case 'text':
        return 'Short Answer';
      case 'paragraph':
        return 'Paragraph';
      case 'multiple_choice':
        return 'Multiple Choice';
      case 'checkboxes':
        return 'Checkboxes';
      case 'dropdown':
        return 'Dropdown';
      case 'email':
        return 'Email';
      case 'number':
        return 'Number';
      case 'date':
        return 'Date';
      case 'time':
        return 'Time';
      case 'rating':
        return 'Rating Scale';
      case 'true_false':
        return 'True/False';
      default:
        return 'Text';
    }
  }

  Widget _buildAnswerDisplay(dynamic answer, String questionType) {
    if (answer == null) {
      return Text(
        'No answer provided',
        style: TextStyle(
          color: Colors.grey[500],
          fontStyle: FontStyle.italic,
        ),
      );
    }

    // Handle rating type specially with stars
    if (questionType == 'rating' && answer is String) {
      final rating = int.tryParse(answer) ?? 0;
      return Row(
        children: [
          ...List.generate(5, (index) {
            return Icon(
              index < rating ? Icons.star : Icons.star_outline,
              color: index < rating ? Colors.amber[600] : Colors.grey[400],
              size: 20,
            );
          }),
          SizedBox(width: 8),
          Text(
            '$rating out of 5 stars',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.green[700],
            ),
          ),
        ],
      );
    }

    // Handle list answers (like checkboxes)
    if (answer is List) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: answer.map<Widget>((item) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
                Expanded(
                  child: Text(
                    item.toString(),
                    style: TextStyle(
                      color: Colors.green[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    // Handle boolean answers
    if (answer is bool || questionType == 'true_false') {
      final boolValue = answer is bool ? answer : (answer.toString().toLowerCase() == 'true');
      return Row(
        children: [
          Icon(
            boolValue ? Icons.check_circle : Icons.cancel,
            color: boolValue ? Colors.green[600] : Colors.red[600],
            size: 20,
          ),
          SizedBox(width: 8),
          Text(
            boolValue ? 'True' : 'False',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: boolValue ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ],
      );
    }

    // Default text display
    return Text(
      answer.toString(),
      style: TextStyle(
        color: Colors.green[800],
        fontWeight: FontWeight.w500,
        fontSize: 15,
      ),
    );
  }
}
