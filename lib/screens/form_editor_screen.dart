import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FormEditorScreen extends StatefulWidget {
  const FormEditorScreen({super.key});

  @override
  _FormEditorScreenState createState() => _FormEditorScreenState();
}

class _FormEditorScreenState extends State<FormEditorScreen> {
  final _titleController = TextEditingController();

  String _generateFormLink(String formId) {
    // Replace this with your actual domain or deep link scheme
    return 'https://yourapp.com/form?formId=$formId';
  }

  Future<void> _publishForm() async {
    try {
      final formData = {
        'title': _titleController.text,
        'questions': [], // TODO: build real questions UI/logic
        'createdBy': FirebaseAuth.instance.currentUser!.uid,
        'createdAt': Timestamp.now(),
        'isPublished': true,
      };

      final docRef = await FirebaseFirestore.instance.collection('forms').add(formData);
      final formId = docRef.id;

      final link = _generateFormLink(formId);

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Form Published'),
          content: Text('Share this link with students:\n$link'),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: link));
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Link copied!')));
                Navigator.pop(context);
              },
              child: Text('Copy Link'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('Error publishing form: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to publish form')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create & Share Form')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Form Title'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _publishForm,
              child: Text('Publish and Share'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}
