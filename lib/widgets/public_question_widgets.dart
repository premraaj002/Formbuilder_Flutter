import 'package:flutter/material.dart';

class TextQuestionWidget extends StatefulWidget {
  final String question;
  final Function(String) onChanged;
  final bool required;
  final String? initialValue;

  const TextQuestionWidget({
    super.key,
    required this.question,
    required this.onChanged,
    this.required = false,
    this.initialValue,
  });

  @override
  State<TextQuestionWidget> createState() => _TextQuestionWidgetState();
}

class _TextQuestionWidgetState extends State<TextQuestionWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.question,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              if (widget.required)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Required',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          TextField(
            controller: _controller,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              hintText: 'Enter your answer',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

class EmailQuestionWidget extends StatefulWidget {
  final String question;
  final Function(String) onChanged;
  final bool required;
  final String? initialValue;

  const EmailQuestionWidget({
    super.key,
    required this.question,
    required this.onChanged,
    this.required = false,
    this.initialValue,
  });

  @override
  State<EmailQuestionWidget> createState() => _EmailQuestionWidgetState();
}

class _EmailQuestionWidgetState extends State<EmailQuestionWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.question,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              if (widget.required)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Required',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          TextField(
            controller: _controller,
            onChanged: widget.onChanged,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Enter your email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(Icons.email, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}

class NumberQuestionWidget extends StatefulWidget {
  final String question;
  final Function(String) onChanged;
  final bool required;
  final String? initialValue;

  const NumberQuestionWidget({
    super.key,
    required this.question,
    required this.onChanged,
    this.required = false,
    this.initialValue,
  });

  @override
  State<NumberQuestionWidget> createState() => _NumberQuestionWidgetState();
}

class _NumberQuestionWidgetState extends State<NumberQuestionWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.question,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              if (widget.required)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Required',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          TextField(
            controller: _controller,
            onChanged: widget.onChanged,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter a number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: Icon(Icons.numbers, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}

class RadioQuestionWidget extends StatefulWidget {
  final String question;
  final List<String> options;
  final Function(String) onChanged;
  final bool required;
  final String? initialValue;

  const RadioQuestionWidget({
    super.key,
    required this.question,
    required this.options,
    required this.onChanged,
    this.required = false,
    this.initialValue,
  });

  @override
  State<RadioQuestionWidget> createState() => _RadioQuestionWidgetState();
}

class _RadioQuestionWidgetState extends State<RadioQuestionWidget> {
  String? selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.question,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              if (widget.required)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Required',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          ...widget.options.map((option) => Container(
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selectedValue == option 
                    ? Colors.blue[300]! 
                    : Colors.grey[300]!,
                width: selectedValue == option ? 2 : 1,
              ),
              color: selectedValue == option 
                  ? Colors.blue[50] 
                  : Colors.transparent,
            ),
            child: RadioListTile<String>(
              title: Text(
                option,
                style: TextStyle(
                  fontWeight: selectedValue == option 
                      ? FontWeight.w500 
                      : FontWeight.normal,
                  color: selectedValue == option 
                      ? Colors.blue[700] 
                      : Colors.grey[700],
                ),
              ),
              value: option,
              groupValue: selectedValue,
              onChanged: (value) {
                setState(() {
                  selectedValue = value;
                });
                if (value != null) widget.onChanged(value);
              },
              activeColor: Colors.blue[600],
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          )).toList(),
        ],
      ),
    );
  }
}

class CheckboxQuestionWidget extends StatefulWidget {
  final String question;
  final List<String> options;
  final Function(List<String>) onChanged;
  final bool required;
  final List<String>? initialValue;

  const CheckboxQuestionWidget({
    super.key,
    required this.question,
    required this.options,
    required this.onChanged,
    this.required = false,
    this.initialValue,
  });

  @override
  State<CheckboxQuestionWidget> createState() => _CheckboxQuestionWidgetState();
}

class _CheckboxQuestionWidgetState extends State<CheckboxQuestionWidget> {
  Set<String> selectedOptions = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      try {
        selectedOptions = Set.from(widget.initialValue!);
      } catch (e) {
        selectedOptions = {};
        print('Invalid checkbox values: ${widget.initialValue}');
      }
    }
  }

  void _toggleOption(String option) {
    setState(() {
      if (selectedOptions.contains(option)) {
        selectedOptions.remove(option);
      } else {
        selectedOptions.add(option);
      }
    });
    widget.onChanged(selectedOptions.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.question,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              if (widget.required)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Required',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          ...widget.options.map((option) => Container(
            margin: EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selectedOptions.contains(option) 
                    ? Colors.blue[300]! 
                    : Colors.grey[300]!,
                width: selectedOptions.contains(option) ? 2 : 1,
              ),
              color: selectedOptions.contains(option) 
                  ? Colors.blue[50] 
                  : Colors.transparent,
            ),
            child: CheckboxListTile(
              title: Text(
                option,
                style: TextStyle(
                  fontWeight: selectedOptions.contains(option) 
                      ? FontWeight.w500 
                      : FontWeight.normal,
                  color: selectedOptions.contains(option) 
                      ? Colors.blue[700] 
                      : Colors.grey[700],
                ),
              ),
              value: selectedOptions.contains(option),
              onChanged: (bool? value) => _toggleOption(option),
              activeColor: Colors.blue[600],
              checkColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          )).toList(),
        ],
      ),
    );
  }
}

class DropdownQuestionWidget extends StatefulWidget {
  final String question;
  final List<String> options;
  final Function(String) onChanged;
  final bool required;
  final String? initialValue;

  const DropdownQuestionWidget({
    super.key,
    required this.question,
    required this.options,
    required this.onChanged,
    this.required = false,
    this.initialValue,
  });

  @override
  State<DropdownQuestionWidget> createState() => _DropdownQuestionWidgetState();
}

class _DropdownQuestionWidgetState extends State<DropdownQuestionWidget> {
  String? selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.question,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              if (widget.required)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Required',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: selectedValue,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            hint: Text('Select an option'),
            items: widget.options.map((option) => DropdownMenuItem(
              value: option,
              child: Text(option),
            )).toList(),
            onChanged: (value) {
              setState(() {
                selectedValue = value;
              });
              if (value != null) {
                widget.onChanged(value);
              }
            },
          ),
        ],
      ),
    );
  }
}

class ParagraphQuestionWidget extends StatefulWidget {
  final String question;
  final Function(String) onChanged;
  final bool required;
  final String? initialValue;

  const ParagraphQuestionWidget({
    super.key,
    required this.question,
    required this.onChanged,
    this.required = false,
    this.initialValue,
  });

  @override
  State<ParagraphQuestionWidget> createState() => _ParagraphQuestionWidgetState();
}

class _ParagraphQuestionWidgetState extends State<ParagraphQuestionWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.question,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              if (widget.required)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Required',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          TextField(
            controller: _controller,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              hintText: 'Enter your answer',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            maxLines: 5,
          ),
        ],
      ),
    );
  }
}

class DateQuestionWidget extends StatefulWidget {
  final String question;
  final Function(String) onChanged;
  final bool required;
  final String? initialValue;

  const DateQuestionWidget({
    super.key,
    required this.question,
    required this.onChanged,
    this.required = false,
    this.initialValue,
  });

  @override
  State<DateQuestionWidget> createState() => _DateQuestionWidgetState();
}

class _DateQuestionWidgetState extends State<DateQuestionWidget> {
  String? selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      try {
        // Try to parse the date, but handle invalid formats gracefully
        DateTime.parse(widget.initialValue!);
        selectedDate = widget.initialValue;
      } catch (e) {
        // If date parsing fails, just ignore it and start with no date selected
        selectedDate = null;
        print('Invalid date format: ${widget.initialValue}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.question,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              if (widget.required)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Required',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
                     InkWell(
             onTap: () async {
               DateTime initialDate;
               try {
                 initialDate = selectedDate != null 
                     ? DateTime.parse(selectedDate!) 
                     : DateTime.now();
               } catch (e) {
                 initialDate = DateTime.now();
               }
               
               final date = await showDatePicker(
                 context: context,
                 initialDate: initialDate,
                 firstDate: DateTime(1900),
                 lastDate: DateTime(2100),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: Colors.blue[600]!,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Colors.grey[800]!,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                final dateString = date.toIso8601String().split('T')[0];
                setState(() {
                  selectedDate = dateString;
                });
                widget.onChanged(dateString);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: selectedDate != null ? Colors.blue[300]! : Colors.grey[400]!,
                  width: selectedDate != null ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: selectedDate != null ? Colors.blue[50] : Colors.grey[50],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: selectedDate != null ? Colors.blue[600] : Colors.grey[600],
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedDate != null 
                          ? 'Selected: ${selectedDate!}'
                          : 'Tap to select date',
                      style: TextStyle(
                        color: selectedDate != null ? Colors.blue[700] : Colors.grey[600],
                        fontWeight: selectedDate != null ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (selectedDate != null)
                    Icon(
                      Icons.check_circle,
                      color: Colors.blue[600],
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TimeQuestionWidget extends StatefulWidget {
  final String question;
  final Function(String) onChanged;
  final bool required;
  final String? initialValue;

  const TimeQuestionWidget({
    super.key,
    required this.question,
    required this.onChanged,
    this.required = false,
    this.initialValue,
  });

  @override
  State<TimeQuestionWidget> createState() => _TimeQuestionWidgetState();
}

class _TimeQuestionWidgetState extends State<TimeQuestionWidget> {
  String? selectedTime;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      try {
        // Try to parse the time, but handle invalid formats gracefully
        TimeOfDay.fromDateTime(DateTime.parse('2000-01-01T${widget.initialValue}:00'));
        selectedTime = widget.initialValue;
      } catch (e) {
        // If time parsing fails, just ignore it and start with no time selected
        selectedTime = null;
        print('Invalid time format: ${widget.initialValue}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.question,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              if (widget.required)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Required',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
                     InkWell(
             onTap: () async {
               TimeOfDay initialTime;
               try {
                 initialTime = selectedTime != null 
                     ? TimeOfDay.fromDateTime(DateTime.parse('2000-01-01T$selectedTime:00'))
                     : TimeOfDay.now();
               } catch (e) {
                 initialTime = TimeOfDay.now();
               }
               
               final time = await showTimePicker(
                 context: context,
                 initialTime: initialTime,
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: ColorScheme.light(
                        primary: Colors.blue[600]!,
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Colors.grey[800]!,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (time != null) {
                final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                setState(() {
                  selectedTime = timeString;
                });
                widget.onChanged(timeString);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(
                  color: selectedTime != null ? Colors.blue[300]! : Colors.grey[400]!,
                  width: selectedTime != null ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: selectedTime != null ? Colors.blue[50] : Colors.grey[50],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: selectedTime != null ? Colors.blue[600] : Colors.grey[600],
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      selectedTime != null 
                          ? 'Selected: ${selectedTime!}'
                          : 'Tap to select time',
                      style: TextStyle(
                        color: selectedTime != null ? Colors.blue[700] : Colors.grey[600],
                        fontWeight: selectedTime != null ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                  if (selectedTime != null)
                    Icon(
                      Icons.check_circle,
                      color: Colors.blue[600],
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RatingQuestionWidget extends StatefulWidget {
  final String question;
  final Function(String) onChanged;
  final bool required;
  final String? initialValue;

  const RatingQuestionWidget({
    super.key,
    required this.question,
    required this.onChanged,
    this.required = false,
    this.initialValue,
  });

  @override
  State<RatingQuestionWidget> createState() => _RatingQuestionWidgetState();
}

class _RatingQuestionWidgetState extends State<RatingQuestionWidget> {
  int? selectedRating;

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      try {
        selectedRating = int.tryParse(widget.initialValue!);
      } catch (e) {
        selectedRating = null;
        print('Invalid rating value: ${widget.initialValue}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.question,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              if (widget.required)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Required',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final rating = index + 1;
              final isHighlighted = selectedRating != null && rating <= selectedRating!;
              final isCurrentlySelected = selectedRating == rating;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedRating = rating;
                  });
                  widget.onChanged(rating.toString());
                },
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    isHighlighted ? Icons.star : Icons.star_outline,
                    size: 36,
                    color: isHighlighted 
                        ? (isCurrentlySelected ? Colors.amber[700] : Colors.amber[500])
                        : Colors.grey[400],
                  ),
                ),
              );
            }),
          ),
          if (selectedRating != null)
            Container(
              margin: EdgeInsets.only(top: 12),
              child: Text(
                'You rated: $selectedRating out of 5',
                style: TextStyle(
                  color: Colors.blue[600],
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class TrueFalseQuestionWidget extends StatefulWidget {
  final String question;
  final Function(String) onChanged;
  final bool required;
  final String? initialValue;

  const TrueFalseQuestionWidget({
    super.key,
    required this.question,
    required this.onChanged,
    this.required = false,
    this.initialValue,
  });

  @override
  State<TrueFalseQuestionWidget> createState() => _TrueFalseQuestionWidgetState();
}

class _TrueFalseQuestionWidgetState extends State<TrueFalseQuestionWidget> {
  String? selectedValue;

  @override
  void initState() {
    super.initState();
    selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.question,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              if (widget.required)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Required',
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selectedValue == 'true' 
                          ? Colors.blue[300]! 
                          : Colors.grey[300]!,
                      width: selectedValue == 'true' ? 2 : 1,
                    ),
                    color: selectedValue == 'true' 
                        ? Colors.blue[50] 
                        : Colors.transparent,
                  ),
                  child: RadioListTile<String>(
                    title: Text(
                      'True',
                      style: TextStyle(
                        fontWeight: selectedValue == 'true' 
                            ? FontWeight.w500 
                            : FontWeight.normal,
                        color: selectedValue == 'true' 
                            ? Colors.blue[700] 
                            : Colors.grey[700],
                      ),
                    ),
                    value: 'true',
                    groupValue: selectedValue,
                    onChanged: (value) {
                      setState(() {
                        selectedValue = value;
                      });
                      if (value != null) widget.onChanged(value);
                    },
                    activeColor: Colors.blue[600],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selectedValue == 'false' 
                          ? Colors.blue[300]! 
                          : Colors.grey[300]!,
                      width: selectedValue == 'false' ? 2 : 1,
                    ),
                    color: selectedValue == 'false' 
                        ? Colors.blue[50] 
                        : Colors.transparent,
                  ),
                  child: RadioListTile<String>(
                    title: Text(
                      'False',
                      style: TextStyle(
                        fontWeight: selectedValue == 'false' 
                            ? FontWeight.w500 
                            : FontWeight.normal,
                        color: selectedValue == 'false' 
                            ? Colors.blue[700] 
                            : Colors.grey[700],
                      ),
                    ),
                    value: 'false',
                    groupValue: selectedValue,
                    onChanged: (value) {
                      setState(() {
                        selectedValue = value;
                      });
                      if (value != null) widget.onChanged(value);
                    },
                    activeColor: Colors.blue[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

