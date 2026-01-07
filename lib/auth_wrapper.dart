import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/dashboard_page.dart';
import 'screens/email_verify_page.dart';
import 'screens/student_dashboard.dart';
import 'screens/role_selection.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<String?> _getUserRole(String uid) async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        print('Error getting user role: No authenticated user found.');
        return null;
      }
      if (FirebaseAuth.instance.currentUser?.uid != uid) {
        print('Error getting user role: UID mismatch between auth and request.');
        return null;
      }
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        if (data != null) {
          print('Successfully retrieved user role for UID: $uid - Role: ${data['role']}');
          return data['role'] as String?;
        }
      } else {
        print('No user document found for UID: $uid - Creating default student document');
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'uid': uid,
          'email': FirebaseAuth.instance.currentUser?.email ?? '',
          'role': 'student',
          'createdAt': Timestamp.now(),
        });
        return 'student';
      }
      return null;
    } catch (e) {
      print('Error getting/creating user role: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Colors.blue[50],
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Prem\'s Form',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[600],
                    ),
                  ),
                  SizedBox(height: 20),
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text('Loading...'),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          User user = snapshot.data!;

          if (user.emailVerified) {
            return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
              builder: (context, roleSnapshot) {
                if (roleSnapshot.connectionState == ConnectionState.waiting) {
                  print('FutureBuilder waiting for role...');
                  return Center(child: CircularProgressIndicator());
                }
                if (roleSnapshot.hasError) {
                  print('Role snapshot error: ${roleSnapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error loading user role. Please try again.'),
                        SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () => FirebaseAuth.instance.signOut(),
                          child: Text('Logout and Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final data = roleSnapshot.data?.data() ?? {};
                final role = (data['role'] as String?) ?? 'student';
                // Apply theme preference if available (defer to next frame to avoid build-phase notify)
                final themePref = data['theme'] as String?; // 'light' | 'dark'
                if (themePref != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      Provider.of<ThemeNotifier>(context, listen: false)
                          .setThemeFromString(themePref);
                    }
                  });
                }
                print('Role determined: $role - Routing now');

                if (role == 'admin') {
                  print('Routing to DashboardScreen');
                  return DashboardScreen();
                } else {
                  print('Routing to StudentDashboardScreen');
                  return StudentDashboardScreen();
                }
              },
            );
          } else {
            return EmailVerificationScreen(email: user.email ?? '');
          }
        }

        return RoleSelectionScreen();
      },
    );
  }
}
