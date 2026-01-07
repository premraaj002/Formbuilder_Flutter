import 'package:flutter/material.dart';

class FormSuccessScreen extends StatelessWidget {
  final String formTitle;
  final String formId;
  final bool isQuiz;
  final int? score;
  final int? totalQuestions;

  const FormSuccessScreen({
    super.key,
    required this.formTitle,
    required this.formId,
    this.isQuiz = false,
    this.score,
    this.totalQuestions,
  });

  @override
  Widget build(BuildContext context) {
    // Force light theme for consistency
    return Theme(
      data: ThemeData.light().copyWith(
        primaryColor: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.grey[800],
          elevation: 0,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'Submission Complete',
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.grey[800]),
          automaticallyImplyLeading: false, // Remove back button
        ),
        body: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: 600),
            margin: EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success animation
                TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 800),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: 0.3 + (0.7 * value),
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          padding: EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 80,
                            color: Colors.green[600],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                SizedBox(height: 32),
                
                // Success message
                Text(
                  isQuiz ? 'Quiz Completed!' : 'Response Submitted!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 16),
                
                Text(
                  isQuiz 
                    ? 'Your quiz has been submitted successfully.'
                    : 'Your response has been recorded successfully.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                // Show score for quiz
                if (isQuiz && score != null && totalQuestions != null) ...[
                  SizedBox(height: 32),
                  Container(
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          size: 48,
                          color: Colors.blue[600],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Your Score',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '$score%',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '${((score! / 100) * totalQuestions!).round()} out of $totalQuestions correct',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.blue[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                SizedBox(height: 48),
                
                // Form title card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isQuiz ? Icons.quiz : Icons.description,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                      SizedBox(height: 8),
                      Text(
                        formTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 48),
                
                // Action buttons
                Column(
                  children: [
                    // Submit another response button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigate back to the form with fresh state
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            isQuiz ? '/public-quiz' : '/public-form',
                            (route) => false,
                            arguments: formId,
                          );
                        },
                        icon: Icon(Icons.add_circle_outline),
                        label: Text(
                          isQuiz ? 'Take Quiz Again' : 'Submit Another Response',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 12),
                    
                    // Close button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Navigate to home or close
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/',
                            (route) => false,
                          );
                        },
                        icon: Icon(Icons.home_outlined),
                        label: Text(
                          'Back to Home',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 32),
                
                // Footer message
                Text(
                  isQuiz 
                    ? 'Thank you for taking this quiz!'
                    : 'Thank you for your response!',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
