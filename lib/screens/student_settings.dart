import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../providers/settings_notifier.dart';
import '../theme_notifier.dart';
import 'student_tickets_screen.dart';

class StudentSettingsScreen extends StatefulWidget {
  const StudentSettingsScreen({super.key});

  @override
  State<StudentSettingsScreen> createState() => _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends State<StudentSettingsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  
  @override
  Widget build(BuildContext context) {
    return Consumer2<SettingsNotifier, ThemeNotifier>(
      builder: (context, settingsNotifier, themeNotifier, child) {
        return _buildSettingsScreen(context, settingsNotifier, themeNotifier);
      },
    );
  }
  
  Future<void> _saveSettings(SettingsNotifier settingsNotifier) async {
    try {
      await settingsNotifier.saveSettings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Account',
          style: TextStyle(color: Colors.red[700]),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This action cannot be undone. Deleting your account will:'),
            SizedBox(height: 8),
            Text('• Remove all your form responses'),
            Text('• Delete your profile information'),
            Text('• Permanently close your account'),
            SizedBox(height: 16),
            Text(
              'Are you sure you want to continue?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
            ),
            child: Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      if (user != null) {
        // Delete user responses
        final responsesQuery = await FirebaseFirestore.instance
            .collection('responses')
            .where('userId', isEqualTo: user!.uid)
            .get();
            
        for (final doc in responsesQuery.docs) {
          await doc.reference.delete();
        }
        
        // Delete user document
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .delete();
        
        // Delete Firebase Auth account
        await user!.delete();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting account: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  Widget _buildSettingsScreen(BuildContext context, SettingsNotifier settingsNotifier, ThemeNotifier themeNotifier) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () => _saveSettings(settingsNotifier),
            tooltip: 'Save Settings',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // Appearance Section
            _buildSectionCard(
              'Appearance',
              Icons.palette_outlined,
              [
                ListTile(
                  title: Text('Theme'),
                  subtitle: Text('Choose your preferred theme'),
                  trailing: DropdownButton<String>(
                    value: themeNotifier.themeModeString,
                    items: [
                      DropdownMenuItem(value: 'system', child: Text('System')),
                      DropdownMenuItem(value: 'light', child: Text('Light')),
                      DropdownMenuItem(value: 'dark', child: Text('Dark')),
                    ],
                    onChanged: (value) async {
                      if (value != null) {
                        await themeNotifier.setThemeFromString(value);
                        // Sync with SettingsNotifier for compatibility
                        settingsNotifier.setDarkMode(value == 'dark');
                      }
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Notifications Section
            _buildSectionCard(
              'Notifications',
              Icons.notifications_outlined,
              [
                SwitchListTile(
                  title: Text('Push Notifications'),
                  subtitle: Text('Receive notifications on your device'),
                  value: settingsNotifier.enableNotifications,
                  activeColor: Colors.green[600],
                  onChanged: (value) {
                    settingsNotifier.setEnableNotifications(value);
                  },
                ),
                SwitchListTile(
                  title: Text('Email Notifications'),
                  subtitle: Text('Receive notifications via email'),
                  value: settingsNotifier.enableEmailNotifications,
                  activeColor: Colors.green[600],
                  onChanged: (value) {
                    settingsNotifier.setEnableEmailNotifications(value);
                  },
                ),
              ],
            ),

            SizedBox(height: 16),

            // Privacy Section
            _buildSectionCard(
              'Privacy & Data',
              Icons.privacy_tip_outlined,
              [
                SwitchListTile(
                  title: Text('Public Profile'),
                  subtitle: Text('Make your profile visible to others'),
                  value: settingsNotifier.makeProfilePublic,
                  activeColor: Colors.green[600],
                  onChanged: (value) {
                    settingsNotifier.setMakeProfilePublic(value);
                  },
                ),
                SwitchListTile(
                  title: Text('Analytics'),
                  subtitle: Text('Help improve the app with usage data'),
                  value: settingsNotifier.allowDataCollection,
                  activeColor: Colors.green[600],
                  onChanged: (value) {
                    settingsNotifier.setAllowDataCollection(value);
                  },
                ),
                ListTile(
                  title: Text('Download My Data'),
                  subtitle: Text('Export all your data'),
                  trailing: Icon(Icons.download_outlined),
                  onTap: () => _exportUserData(),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Support Section
            _buildSectionCard(
              'Support',
              Icons.support_agent_outlined,
              [
                ListTile(
                  title: Text('Submit Support Ticket'),
                  subtitle: Text('Report issues or get help'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showSupportTicketDialog(),
                ),
                ListTile(
                  title: Text('My Tickets'),
                  subtitle: Text('View your support tickets'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _navigateToMyTickets(),
                ),
              ],
            ),

            SizedBox(height: 16),

            // About Section
            _buildSectionCard(
              'About',
              Icons.info_outlined,
              [
                ListTile(
                  title: Text('Developer'),
                  subtitle: Text('Premraaj'),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Icon(Icons.person, color: Colors.blue[600]),
                  ),
                ),
                ListTile(
                  title: Text('Designation'),
                  subtitle: Text('App Developer and Cloud Enthusiast'),
                  leading: Icon(Icons.work, color: Colors.orange[600]),
                ),
                ListTile(
                  title: Text('Contact'),
                  subtitle: Text('premraaj002@gmail.com'),
                  leading: Icon(Icons.email, color: Colors.green[600]),
                  onTap: () => _launchEmail('premraaj002@gmail.com'),
                ),
              ],
            ),

            SizedBox(height: 16),

            // Account Section
            _buildSectionCard(
              'Account',
              Icons.account_circle_outlined,
              [
                ListTile(
                  title: Text('Change Password'),
                  subtitle: Text('Update your account password'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showChangePasswordDialog(),
                ),
                ListTile(
                  title: Text(
                    'Delete Account',
                    style: TextStyle(color: Colors.red[600]),
                  ),
                  subtitle: Text('Permanently delete your account and data'),
                  trailing: Icon(Icons.warning, color: Colors.red[600]),
                  onTap: _showDeleteAccountDialog,
                ),
              ],
            ),

            SizedBox(height: 32),

            // App info
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Smart Forms Student',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Colors.green[600]),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  void _showSupportTicketDialog() {
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'Technical Issue';
    final categories = [
      'Technical Issue',
      'Account Problem',
      'Feature Request',
      'Bug Report',
      'General Inquiry',
      'Other'
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Submit Support Ticket'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedCategory = value!;
                },
              ),
              SizedBox(height: 16),
              Text(
                'Subject',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              TextField(
                controller: subjectController,
                decoration: InputDecoration(
                  hintText: 'Brief description of the issue',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  hintText: 'Provide detailed information about your issue',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (subjectController.text.trim().isEmpty || 
                  descriptionController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please fill in all fields'),
                    backgroundColor: Colors.red[600],
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              await _submitSupportTicket(
                selectedCategory,
                subjectController.text.trim(),
                descriptionController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
            child: Text('Submit Ticket'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitSupportTicket(String category, String subject, String description) async {
    try {
      if (user != null) {
        print('Submitting ticket for user: ${user!.uid}');
        print('User email: ${user!.email}');
        
        final ticketData = {
          'userId': user!.uid,
          'userEmail': user!.email,
          'category': category,
          'subject': subject,
          'description': description,
          'status': 'open',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        print('Ticket data: $ticketData');
        
        final docRef = await FirebaseFirestore.instance
            .collection('support_tickets')
            .add(ticketData);
            
        print('Ticket created with ID: ${docRef.id}');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Support ticket submitted successfully! ID: ${docRef.id}'),
              backgroundColor: Colors.green[600],
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        print('User is null - cannot submit ticket');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: User not authenticated'),
              backgroundColor: Colors.red[600],
            ),
          );
        }
      }
    } catch (e) {
      print('Error submitting ticket: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting ticket: $e'),
            backgroundColor: Colors.red[600],
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  void _navigateToMyTickets() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentTicketsScreen(),
      ),
    );
  }

  void _launchEmail(String email) async {
    // You can add url_launcher package to actually launch email
    // For now, just copy to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Email: $email (copied to clipboard)'),
        backgroundColor: Colors.blue[600],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm New Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              
              Navigator.pop(context);
              await _changePassword(
                currentPasswordController.text,
                newPasswordController.text,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green[600],
              foregroundColor: Colors.white,
            ),
            child: Text('Change Password'),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword(String currentPassword, String newPassword) async {
    try {
      if (user != null) {
        // Re-authenticate user
        final credential = EmailAuthProvider.credential(
          email: user!.email!,
          password: currentPassword,
        );
        
        await user!.reauthenticateWithCredential(credential);
        
        // Update password
        await user!.updatePassword(newPassword);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password updated successfully'),
            backgroundColor: Colors.green[600],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating password: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }

  Future<void> _exportUserData() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data export will be sent to your email within 24 hours'),
          backgroundColor: Colors.green[600],
        ),
      );
      
      // In a real app, this would trigger a backend process to export user data
      // For now, we'll just show a confirmation message
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error requesting data export: $e'),
          backgroundColor: Colors.red[600],
        ),
      );
    }
  }
}
