import 'package:flutter/material.dart';

class PublicQuizQuestionWidget extends StatefulWidget {
  final int questionNumber;
  final String question;
  final List<String> options;
  final Function(String) onChanged;

  const PublicQuizQuestionWidget({
    super.key,
    required this.questionNumber,
    required this.question,
    required this.options,
    required this.onChanged,
  });

  @override
  State<PublicQuizQuestionWidget> createState() => _PublicQuizQuestionWidgetState();
}

class _PublicQuizQuestionWidgetState extends State<PublicQuizQuestionWidget> {
  String? selectedAnswer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Question ${widget.questionNumber}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[700],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            widget.question,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16),
          ...widget.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            return RadioListTile<String>(
              title: Text(option),
              value: option,
              groupValue: selectedAnswer,
              onChanged: (value) {
                setState(() {
                  selectedAnswer = value;
                });
                if (value != null) {
                  widget.onChanged(value);
                }
              },
              contentPadding: EdgeInsets.zero,
              activeColor: Colors.purple[600],
            );
          }).toList(),
        ],
      ),
    );
  }
}
