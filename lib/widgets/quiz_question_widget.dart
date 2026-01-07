import 'package:flutter/material.dart';
import '../models/form_models.dart';

class QuizQuestionWidget extends StatefulWidget {
  final FormQuestion question;
  final int questionNumber;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(FormQuestion) onUpdate;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const QuizQuestionWidget({
    super.key,
    required this.question,
    required this.questionNumber,
    required this.isSelected,
    required this.onTap,
    required this.onUpdate,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  _QuizQuestionWidgetState createState() => _QuizQuestionWidgetState();
}

class _QuizQuestionWidgetState extends State<QuizQuestionWidget> {
  late TextEditingController _titleController;
  late TextEditingController _pointsController;
  List<TextEditingController> _optionControllers = [];
  String? _selectedCorrectAnswer;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.question.title);
    _pointsController = TextEditingController(text: widget.question.points.toString());
    
    if (widget.question.options != null) {
      _optionControllers = widget.question.options!
          .map((option) => TextEditingController(text: option))
          .toList();
    }
    
    _selectedCorrectAnswer = widget.question.correctAnswer;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pointsController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _saveChanges() {
    final updatedQuestion = widget.question.copyWith(
      title: _titleController.text,
      options: _optionControllers.isEmpty 
          ? null 
          : _optionControllers.map((c) => c.text).where((text) => text.isNotEmpty).toList(),
      correctAnswer: _selectedCorrectAnswer,
      points: int.tryParse(_pointsController.text) ?? 1,
    );
    widget.onUpdate(updatedQuestion);
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController(text: 'Option ${_optionControllers.length + 1}'));
    });
    _saveChanges();
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        final removedText = _optionControllers[index].text;
        if (_selectedCorrectAnswer == removedText) {
          _selectedCorrectAnswer = null;
        }
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
      _saveChanges();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected ? Color(0xFF34A853) : colorScheme.outline.withOpacity(0.2),
              width: widget.isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Color(0xFF34A853),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.questionNumber}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getQuestionTypeLabel(widget.question.type),
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF34A853),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (widget.isSelected) ...[
                    IconButton(
                      icon: Icon(Icons.content_copy, size: 16),
                      onPressed: widget.onDuplicate,
                      tooltip: 'Duplicate',
                      padding: EdgeInsets.all(4),
                      constraints: BoxConstraints(),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 16, color: Colors.red[600]),
                      onPressed: widget.onDelete,
                      tooltip: 'Delete',
                      padding: EdgeInsets.all(4),
                      constraints: BoxConstraints(),
                    ),
                  ],
                ],
              ),
              
              SizedBox(height: 16),
              
              TextField(
                controller: _titleController,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText: 'Question title',
                  border: widget.isSelected ? UnderlineInputBorder() : InputBorder.none,
                  hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                onChanged: (_) => _saveChanges(),
              ),
              
              SizedBox(height: 16),
              
              _buildQuestionOptions(),
              
              if (widget.isSelected) ...[
                SizedBox(height: 16),
                
                Row(
                  children: [
                    Text(
                      'Points: ',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: _pointsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => _saveChanges(),
                      ),
                    ),
                    Spacer(),
                    if (_selectedCorrectAnswer == null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Set correct answer',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Answer set ✓',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionOptions() {
    switch (widget.question.type) {
      case 'multiple_choice':
        return _buildMultipleChoiceOptions();
      case 'true_false':
        return _buildTrueFalseOptions();
      case 'short_answer':
        return _buildShortAnswerOption();
      default:
        return Container();
    }
  }

  Widget _buildMultipleChoiceOptions() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Options (select correct answer):',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        SizedBox(height: 8),
        ...List.generate(_optionControllers.length, (index) {
          return Container(
            margin: EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Radio<String>(
                  value: _optionControllers[index].text,
                  groupValue: _selectedCorrectAnswer,
                  onChanged: (value) {
                    setState(() {
                      _selectedCorrectAnswer = value;
                    });
                    _saveChanges();
                  },
                  activeColor: Color(0xFF34A853),
                ),
                Expanded(
                  child: TextField(
                    controller: _optionControllers[index],
                    decoration: InputDecoration(
                      hintText: 'Option ${index + 1}',
                      border: widget.isSelected ? UnderlineInputBorder() : InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                    onChanged: (value) {
                      // Update correct answer if this option was selected
                      if (_selectedCorrectAnswer == _optionControllers[index].text) {
                        _selectedCorrectAnswer = value;
                      }
                      _saveChanges();
                    },
                  ),
                ),
                if (widget.isSelected && _optionControllers.length > 2)
                  IconButton(
                    icon: Icon(Icons.close, size: 16, color: Colors.grey[600]),
                    onPressed: () => _removeOption(index),
                    padding: EdgeInsets.all(4),
                    constraints: BoxConstraints(),
                  ),
              ],
            ),
          );
        }),
        if (widget.isSelected)
          TextButton.icon(
            onPressed: _addOption,
            icon: Icon(Icons.add, size: 16),
            label: Text('Add option'),
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF34A853),
              padding: EdgeInsets.zero,
            ),
          ),
      ],
    );
  }

  Widget _buildTrueFalseOptions() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select correct answer:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Radio<String>(
              value: 'True',
              groupValue: _selectedCorrectAnswer,
              onChanged: (value) {
                setState(() {
                  _selectedCorrectAnswer = value;
                });
                _saveChanges();
              },
              activeColor: Color(0xFF34A853),
            ),
            Text('True'),
            SizedBox(width: 24),
            Radio<String>(
              value: 'False',
              groupValue: _selectedCorrectAnswer,
              onChanged: (value) {
                setState(() {
                  _selectedCorrectAnswer = value;
                });
                _saveChanges();
              },
              activeColor: Color(0xFF34A853),
            ),
            Text('False'),
          ],
        ),
      ],
    );
  }

  Widget _buildShortAnswerOption() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Correct answer:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: 'Enter the correct answer',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _selectedCorrectAnswer = value;
            _saveChanges();
          },
        ),
      ],
    );
  }

  String _getQuestionTypeLabel(String type) {
    switch (type) {
      case 'multiple_choice':
        return 'Multiple Choice';
      case 'true_false':
        return 'True/False';
      case 'short_answer':
        return 'Short Answer';
      default:
        return 'Quiz Question';
    }
  }
}
