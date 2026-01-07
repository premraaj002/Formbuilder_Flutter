import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import 'student_profile.dart';
import 'student_feedback.dart';
import 'student_response_detail.dart';
import 'student_settings.dart';
import 'student_tickets_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  _StudentDashboardScreenState createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  AppUser? _appUser;
  bool _isLoading = true;
  List<DocumentSnapshot> _responses = [];
  bool _isLoadingResponses = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadResponses();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _appUser = AppUser.fromMap(doc.data()!);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadResponses() async {
    if (user == null) return;

    setState(() => _isLoadingResponses = true);

    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('responses')
          .where('userId', isEqualTo: user!.uid)
          .orderBy('submittedAt', descending: true)
          .get();

      setState(() {
        _responses = querySnapshot.docs;
      });
    } catch (e) {
      print('Error loading responses: $e');
    } finally {
      setState(() => _isLoadingResponses = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Student Dashboard'),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadResponses,
          ),
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _appUser?.name?.substring(0, 1) ?? 'S',
                style: TextStyle(color: Colors.green[600]),
              ),
            ),
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StudentProfileScreen(user: _appUser)),
                );
              } else if (value == 'feedback') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StudentFeedbackScreen()),
                );
              } else if (value == 'tickets') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StudentTicketsScreen()),
                );
              } else if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StudentSettingsScreen()),
                );
              } else if (value == 'logout') {
                FirebaseAuth.instance.signOut();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline, color: Colors.grey[700]),
                    SizedBox(width: 12),
                    Text('Profile'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'feedback',
                child: Row(
                  children: [
                    Icon(Icons.feedback_outlined, color: Colors.grey[700]),
                    SizedBox(width: 12),
                    Text('Feedback'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'tickets',
                child: Row(
                  children: [
                    Icon(Icons.support_agent_outlined, color: Colors.grey[700]),
                    SizedBox(width: 12),
                    Text('Support Tickets'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, color: Colors.grey[700]),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red[600]),
                    SizedBox(width: 12),
                    Text('Logout', style: TextStyle(color: Colors.red[600])),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.green[100],
                      child: Icon(Icons.person, color: Colors.green[600]),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _appUser?.name ?? 'Student',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _appUser?.email ?? '',
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Divider(),
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Your Responses',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: _isLoadingResponses
                ? Center(child: CircularProgressIndicator())
                : _responses.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[400]),
                  SizedBox(height: 12),
                  Text(
                    'No responses yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _responses.length,
              itemBuilder: (context, index) {
                final response = _responses[index];
                final data = response.data() as Map<String, dynamic>;
                final formTitle = data['formTitle'] ?? 'Untitled Form';
                final submittedAt = (data['submittedAt'] as Timestamp).toDate();

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(Icons.assignment_turned_in, color: Colors.green[600]),
                    title: Text(formTitle),
                    subtitle: Text('Submitted on ${submittedAt.toString().substring(0, 10)}'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StudentResponseDetailScreen(
                            responseData: data,
                            responseId: response.id,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}