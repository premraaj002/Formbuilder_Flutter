import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FormFillScreen extends StatefulWidget {
  final String formId;
  const FormFillScreen({super.key, required this.formId});

  @override
  _FormFillScreenState createState() => _FormFillScreenState();
}

class _FormFillScreenState extends State<FormFillScreen> {
  Map<String, dynamic>? formData;

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  Future<void> _loadForm() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('forms')
          .doc(widget.formId)
          .get();
      if (doc.exists) {
        setState(() => formData = doc.data());
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Form not found')));
      }
    } catch (e) {
      print('Error loading form: $e');
    }
  }

  Future<void> _submitResponse() async {
    final responseData = {
      'formId': widget.formId,
      'userId': FirebaseAuth.instance.currentUser!.uid,
      'answers': {}, // TODO: Collect answers from UI fields
      'submittedAt': Timestamp.now(),
      'formOwnerId': formData?['createdBy'],
    };

    await FirebaseFirestore.instance
        .collection('responses')
        .add(responseData);

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Response submitted!')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (formData == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Loading Form...')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(formData!['title'] ?? 'Untitled Form')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // TODO: Dynamically create question widgets from formData['questions']
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitResponse,
              child: Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
