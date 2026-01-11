import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'form_builder_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'quiz_builder_screen.dart';
import 'form_editor_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:excel/excel.dart' as xls;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:qr_flutter/qr_flutter.dart';
import '../theme_notifier.dart';
import '../utils/responsive.dart';
import 'analytics_screen.dart';
import '../services/excel_export_service.dart';
import 'dart:async';
import '../services/template_service.dart';
import '../models/template_models.dart';
import 'template_selection_screen.dart';
import 'package:provider/provider.dart';
import '../providers/settings_notifier.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class FormAnalytics {
  FormAnalytics({required this.formId, required this.title, required this.responseCount, required this.numericAverages});
  final String formId;
  final String title;
  final int responseCount;
  final Map<String, double> numericAverages; // key: question title, value: average
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<DocumentSnapshot> _userForms = [];
  bool _isLoadingForms = false;
  List<DocumentSnapshot> _trashedForms = [];
  bool _isLoadingTrashedForms = false;
  List<DocumentSnapshot> _userQuizzes = [];
  bool _isLoadingQuizzes = false;
  List<DocumentSnapshot> _starredForms = [];
  bool _isLoadingStarredForms = false;
  bool _notifyEmail = true;
  bool _notifyApp = true;
  bool _isLoadingAnalytics = false;
  List<FormAnalytics> _formAnalytics = [];

  @override
  void initState() {
    super.initState();
    _loadUserForms();
    _loadTrashedForms();
    _loadUserQuizzes();
    _loadStarredForms();
  }

  Future<void> _loadUserForms() async {
    if (!mounted) return;
    setState(() => _isLoadingForms = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('forms')
            .where('createdBy', isEqualTo: user.uid)
            .where('isDeleted', isEqualTo: false)
            .orderBy('updatedAt', descending: true)
            .get();

        if (!mounted) return;
        setState(() {
          _userForms = querySnapshot.docs;
        });
      }
    } catch (e) {
      print('Error loading forms: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading forms: $e'),
          ),
        );
    } finally {
      if (mounted) {
        setState(() => _isLoadingForms = false);
      }
    }
  }

  Future<void> _loadTrashedForms() async {
    if (!mounted) return;
    setState(() => _isLoadingTrashedForms = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('forms')
            .where('createdBy', isEqualTo: user.uid)
            .where('isDeleted', isEqualTo: true)
            .orderBy('deletedAt', descending: true)
            .get();

        if (!mounted) return;
        setState(() {
          _trashedForms = querySnapshot.docs;
        });
      }
    } catch (e) {
      print('Error loading trashed forms: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingTrashedForms = false);
      }
    }
  }

  Future<void> _loadUserQuizzes() async {
    if (!mounted) return;
    setState(() => _isLoadingQuizzes = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('forms')
            .where('createdBy', isEqualTo: user.uid)
            .where('isDeleted', isEqualTo: false)
            .where('isQuiz', isEqualTo: true)
            .orderBy('updatedAt', descending: true)
            .get();

        if (!mounted) return;
        setState(() {
          _userQuizzes = querySnapshot.docs;
        });
      }
    } catch (e) {
      print('Error loading quizzes: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingQuizzes = false);
      }
    }
  }

  Future<void> _loadStarredForms() async {
    if (!mounted) return;
    setState(() => _isLoadingStarredForms = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Simplified query that doesn't require a composite index
        final querySnapshot = await FirebaseFirestore.instance
            .collection('forms')
            .where('createdBy', isEqualTo: user.uid)
            .where('isDeleted', isEqualTo: false)
            .where('isStarred', isEqualTo: true)
            .get();
        
        // Sort manually in client
        final sortedDocs = querySnapshot.docs;
        sortedDocs.sort((a, b) {
          // Handle both Timestamp and String types
          dynamic aTime = a.data()['updatedAt'];
          dynamic bTime = b.data()['updatedAt'];
          
          // Convert to Timestamp if needed
          Timestamp? aTimestamp;
          Timestamp? bTimestamp;
          
          if (aTime is Timestamp) {
            aTimestamp = aTime;
          } else if (aTime is String) {
            try {
              aTimestamp = Timestamp.fromDate(DateTime.parse(aTime));
            } catch (e) {
              // Invalid date string, treat as null
              aTimestamp = null;
            }
          }
          
          if (bTime is Timestamp) {
            bTimestamp = bTime;
          } else if (bTime is String) {
            try {
              bTimestamp = Timestamp.fromDate(DateTime.parse(bTime));
            } catch (e) {
              // Invalid date string, treat as null
              bTimestamp = null;
            }
          }
          
          if (aTimestamp == null && bTimestamp == null) return 0;
          if (aTimestamp == null) return 1;
          if (bTimestamp == null) return -1;
          return bTimestamp.compareTo(aTimestamp); // Descending order
        });

        if (!mounted) return;
        setState(() {
          _starredForms = sortedDocs;
        });
      }
    } catch (e) {
      print('Error loading starred forms: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingStarredForms = false);
      }
    }
  }

  Future<void> _toggleStar(String formId, bool currentStarStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('forms')
          .doc(formId)
          .update({
        'isStarred': !currentStarStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Reload all relevant lists
      _loadUserForms();
      _loadStarredForms();
      _loadUserQuizzes();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !currentStarStatus ? 'Added to starred' : 'Removed from starred',
          ),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating star status: $e'),
        ),
      );
    }
  }

  Future<void> _loadAnalytics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isLoadingAnalytics = true);
    try {
      // Load all non-deleted forms for user
      final formsSnap = await FirebaseFirestore.instance
          .collection('forms')
          .where('createdBy', isEqualTo: user.uid)
          .where('isDeleted', isEqualTo: false)
          .get();

      final List<FormAnalytics> results = [];
      for (final form in formsSnap.docs) {
        final formData = form.data();
        final title = (formData['title'] ?? 'Untitled Form').toString();

        // Count responses to this form
        final responsesSnap = await FirebaseFirestore.instance
            .collection('responses')
            .where('formId', isEqualTo: form.id)
            .where('formOwnerId', isEqualTo: user.uid)
            .get();

        final int responseCount = responsesSnap.size;

        // Compute numeric averages if any question has numeric/ rating type
        final List questions = (formData['questions'] as List?) ?? [];
        final Map<String, double> numericAverages = {};
        if (questions.isNotEmpty && responsesSnap.docs.isNotEmpty) {
          for (final q in questions) {
            final Map<String, dynamic> qMap = Map<String, dynamic>.from(q as Map);
            final String qType = (qMap['type'] ?? '').toString();
            final String qTitle = (qMap['title'] ?? '').toString();
            if (qType == 'number' || qType == 'rating') {
              double sum = 0;
              int count = 0;
              for (final r in responsesSnap.docs) {
                final rData = r.data();
                final answers = (rData['answers'] as Map?) ?? {};
                final value = answers[qMap['id']] ?? answers[qTitle];
                if (value != null) {
                  final num? n = value is num ? value : num.tryParse(value.toString());
                  if (n != null) {
                    sum += n.toDouble();
                    count += 1;
                  }
                }
              }
              if (count > 0) {
                numericAverages[qTitle.isNotEmpty ? qTitle : (qMap['id'] ?? '').toString()] = sum / count;
              }
            }
          }
        }

        results.add(FormAnalytics(
          formId: form.id,
          title: title,
          responseCount: responseCount,
          numericAverages: numericAverages,
        ));
      }

      if (!mounted) return;
      setState(() => _formAnalytics = results);
    } catch (e) {
      if (!mounted) return;
      String msg = 'Failed to load analytics';
      if (e is FirebaseException) {
        msg = 'Analytics error: ${e.code} - ${e.message}';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) {
        setState(() => _isLoadingAnalytics = false);
      }
    }
  }

  Future<void> _exportAnalyticsToExcel() async {
    try {
      final excel = xls.Excel.createExcel();
      final xls.Sheet sheet = excel['Analytics'];
      sheet.appendRow(['Form Title', 'Responses', 'Metric', 'Average']);

      for (final fa in _formAnalytics) {
        if (fa.numericAverages.isEmpty) {
          sheet.appendRow([fa.title, fa.responseCount, '-', '-']);
        } else {
          for (final entry in fa.numericAverages.entries) {
            sheet.appendRow([fa.title, fa.responseCount, entry.key, entry.value]);
          }
        }
      }

      final bytes = excel.encode()!;

      if (kIsWeb) {
        final base64Data = base64Encode(bytes);
        html.AnchorElement(
            href: 'data:application/vnd.openxmlformats-officedocument.spreadsheetml.sheet;base64,$base64Data')
          ..setAttribute('download', 'analytics.xlsx')
          ..click();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }

  String _formLink(String formId) {
    if (kIsWeb) {
      final origin = html.window.location.origin;
      return '$origin/forms/$formId';
    }
    return 'https://yourdomain.com/forms/$formId';
  }
  Future<void> _showFormLinkDialog(String formId, String title) async {
    final doc = await FirebaseFirestore.instance.collection('forms').doc(formId).get();
    final isPublished = (doc.data()?['isPublished'] ?? false) as bool;
    final link = _formLink(formId);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Share "$title"'),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              QrImageView(data: link, size: 180),
              SizedBox(height: 12),
              SelectableText(link, style: TextStyle(fontSize: 12)),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: link));
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Link copied to clipboard')),
                    );
                  },
                  icon: Icon(Icons.copy),
                  label: Text('Copy link'),
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPublished ? Icons.check_circle : Icons.info_outline, 
                    color: isPublished ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary, 
                    size: 18
                  ),
                  SizedBox(width: 6),
                  Text(
                    isPublished ? 'Published' : 'Draft', 
                    style: TextStyle(
                      fontWeight: FontWeight.w500, 
                      color: isPublished ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.secondary
                    )
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
        ],
      ),
    );
  }

  Future<void> _shareForm(String formId, String title) async {
    try {
      final dynamicLink = _formLink(formId);
      await Share.share(
        'Check out this form: "$title"\n\nFill it out here: $dynamicLink',
        subject: 'Form: $title',
      );
      if (!kIsWeb) {
        // Also copy to clipboard for convenience on mobile/desktop
        await Clipboard.setData(ClipboardData(text: dynamicLink));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Form link copied to clipboard')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing form: $e')),
      );
    }
  }
  
  // Dashboard-specific export wrapper with additional safeguards
  static bool _isDashboardExporting = false;
  static String? _lastExportedFormId;
  static DateTime? _lastDashboardExportTime;
  
  Future<void> _exportFormFromDashboard(String formId, String formTitle) async {
    print('=== DASHBOARD EXPORT WRAPPER TRIGGERED ===');
    print('Form ID: $formId');
    print('Form Title: $formTitle');
    
    // Prevent duplicate exports at dashboard level
    if (_isDashboardExporting) {
      print('Dashboard export already in progress, ignoring duplicate request');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export already in progress, please wait...'),
          backgroundColor: Colors.orange[600],
        ),
      );
      return;
    }
    
    // Prevent rapid successive exports of the same form
    final now = DateTime.now();
    if (_lastExportedFormId == formId && 
        _lastDashboardExportTime != null && 
        now.difference(_lastDashboardExportTime!).inSeconds < 5) {
      print('Same form exported too recently, ignoring duplicate request');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please wait a moment before exporting the same form again'),
          backgroundColor: Colors.orange[600],
        ),
      );
      return;
    }
    
    _isDashboardExporting = true;
    _lastExportedFormId = formId;
    _lastDashboardExportTime = now;
    
    try {
      await ExcelExportService.exportFormToExcel(
        formId: formId,
        formTitle: formTitle,
        context: context,
        showCharts: true,
      );
      print('=== DASHBOARD EXPORT COMPLETED SUCCESSFULLY ===');
    } catch (e) {
      print('=== DASHBOARD EXPORT FAILED: $e ===');
      rethrow;
    } finally {
      _isDashboardExporting = false;
    }
  }

  Future<void> _duplicateForm(String formId) async {
    try {
      final formDoc = await FirebaseFirestore.instance
          .collection('forms')
          .doc(formId)
          .get();

      if (formDoc.exists) {
        final formData = formDoc.data()!;
        formData['title'] = '${formData['title']} (Copy)';
        formData['isPublished'] = false;
        formData['createdAt'] = DateTime.now().toIso8601String();
        formData['updatedAt'] = DateTime.now().toIso8601String();

        await FirebaseFirestore.instance
            .collection('forms')
            .add(formData);

        _loadUserForms();
        _loadUserQuizzes();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Form duplicated successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error duplicating form: $e')),
      );
    }
  }

  Future<void> _deleteForm(String formId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Move to Trash'),
        content: Text('Are you sure you want to move this form to trash?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.secondary),
            child: Text('Move to Trash'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('forms')
            .doc(formId)
            .update({
          'isDeleted': true,
          'deletedAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        _loadUserForms();
        _loadUserQuizzes();
        _loadTrashedForms();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Form moved to trash successfully!'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => _restoreForm(formId),
            ),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error moving form to trash: $e')),
        );
      }
    }
  }

  Future<void> _restoreForm(String formId) async {
    try {
      await FirebaseFirestore.instance
          .collection('forms')
          .doc(formId)
          .update({
        'isDeleted': false,
        'deletedAt': null,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      _loadUserForms();
      _loadUserQuizzes();
      _loadTrashedForms();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Form restored successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error restoring form: $e')),
      );
    }
  }

  Future<void> _permanentlyDeleteForm(String formId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Permanently Delete'),
        content: Text('Are you sure you want to permanently delete this form? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text('Delete Forever'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('forms')
            .doc(formId)
            .delete();

        _loadTrashedForms();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Form permanently deleted!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting form: $e')),
        );
      }
    }
  }

  Future<void> _emptyTrash() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Empty Trash'),
        content: Text('Are you sure you want to permanently delete all forms in trash? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text('Empty Trash'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final batch = FirebaseFirestore.instance.batch();
        for (final form in _trashedForms) {
          batch.delete(form.reference);
        }
        await batch.commit();

        _loadTrashedForms();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Trash emptied successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error emptying trash: $e')),
        );
      }
    }
  }

  String _getTimeAgo(String isoString) {
    final dateTime = DateTime.parse(isoString);
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          "Prem's Form",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 1,
        automaticallyImplyLeading: Responsive.isMobile(context),
        leading: Responsive.isMobile(context)
            ? IconButton(
          icon: Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        )
            : null,
        actions: [
          if (Responsive.isMobile(context))
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => _showCreateDialog(),
            ),
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundColor: colorScheme.primary,
              radius: Responsive.valueWhen(context, mobile: 14, desktop: 16),
              child: Text(
                (FirebaseAuth.instance.currentUser?.displayName?.isNotEmpty == true
                        ? FirebaseAuth.instance.currentUser!.displayName!.substring(0, 1)
                        : FirebaseAuth.instance.currentUser?.email?.substring(0, 1) ?? 'A')
                    .toUpperCase(),
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.fontSizeWhen(context, mobile: 12, desktop: 14),
                ),
              ),
            ),
            onSelected: (value) async {
              if (value == 'logout') {
                bool? shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text('Logout'),
                    content: Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF1A73E8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: Text('Logout', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true) {
                  await FirebaseAuth.instance.signOut();
                }
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
          SizedBox(width: Responsive.valueWhen(context, mobile: 8, desktop: 16)),
        ],
      ),
      drawer: Responsive.isMobile(context) ? _buildMobileDrawer() : null,
      bottomNavigationBar: Responsive.isMobile(context) ? _buildBottomNavBar() : null,
      body: ResponsiveWidget(
        mobile: _buildMobileLayout(),
        desktop: _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 280,
          color: colorScheme.surface,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(20),
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateDialog(),
                  icon: Icon(Icons.add, color: Colors.white),
                  label: Text('Create', style: TextStyle(color: Colors.white, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF1A73E8),
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: 2,
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  children: [
                    _buildNavItem(Icons.description_outlined, 'Recent forms', 0),
                    _buildNavItem(Icons.folder_outlined, 'My forms', 1),
                    _buildNavItem(Icons.quiz_outlined, 'My quizzes', 2),
                    _buildNavItem(Icons.star_outline, 'Starred', 3),
                    _buildNavItem(Icons.delete_outline, 'Trash', 4),
                    SizedBox(height: 20),
                    Divider(),
                    _buildNavItem(Icons.analytics_outlined, 'Analytics', 5),
                    _buildNavItem(Icons.settings_outlined, 'Settings', 6),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(width: 1, color: Colors.grey[300]),
        Expanded(
          child: _buildMainContent(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return _buildMainContent();
  }

  Widget _buildMobileDrawer() {
    final colorScheme = Theme.of(context).colorScheme;
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.onPrimary,
                  radius: 30,
                  child: Text(
                    (FirebaseAuth.instance.currentUser?.displayName?.isNotEmpty == true
                            ? FirebaseAuth.instance.currentUser!.displayName!.substring(0, 1)
                            : FirebaseAuth.instance.currentUser?.email?.substring(0, 1) ?? 'A')
                        .toUpperCase(),
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  FirebaseAuth.instance.currentUser?.displayName?.isNotEmpty == true
                      ? FirebaseAuth.instance.currentUser!.displayName!
                      : (FirebaseAuth.instance.currentUser?.email ?? 'Admin'),
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showCreateDialog();
              },
              icon: Icon(Icons.add, color: Colors.white),
              label: Text('Create', style: TextStyle(color: Colors.white, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                minimumSize: Size(double.infinity, 45),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                elevation: 2,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMobileNavItem(Icons.description_outlined, 'Recent forms', 0),
                _buildMobileNavItem(Icons.folder_outlined, 'My forms', 1),
                _buildMobileNavItem(Icons.quiz_outlined, 'My quizzes', 2),
                _buildMobileNavItem(Icons.star_outline, 'Starred', 3),
                _buildMobileNavItem(Icons.delete_outline, 'Trash', 4),
                Divider(),
                _buildMobileNavItem(Icons.analytics_outlined, 'Analytics', 5),
                _buildMobileNavItem(Icons.settings_outlined, 'Settings', 6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return BottomNavigationBar(
      currentIndex: _selectedIndex > 4 ? 0 : _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Color(0xFF1A73E8),
      unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
      selectedFontSize: 12,
      unselectedFontSize: 12,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.description_outlined),
          label: 'Recent',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.folder_outlined),
          label: 'My Forms',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.quiz_outlined),
          label: 'Quizzes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.star_outline),
          label: 'Starred',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          label: 'More',
        ),
      ],
    );
  }

  Widget _buildMobileNavItem(IconData icon, String title, int index) {
    bool isSelected = _selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Color(0xFF1A73E8) : colorScheme.onSurface.withOpacity(0.7),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? Color(0xFF1A73E8) : colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: Color(0xFF1A73E8).withOpacity(0.1),
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildNavItem(IconData icon, String title, int index) {
    bool isSelected = _selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Color(0xFF1A73E8) : colorScheme.onSurface.withOpacity(0.7),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Color(0xFF1A73E8) : colorScheme.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedTileColor: Color(0xFF1A73E8).withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildMainContent() {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    switch (_selectedIndex) {
      case 0:
        return _buildRecentForms(isDesktop);
      case 1:
        return _buildMyForms(isDesktop);
      case 2:
        return _buildMyQuizzes(isDesktop);
      case 3:
        return _buildStarred(isDesktop);
      case 4:
        return _buildTrash(isDesktop);
      case 5:
        return _buildAnalytics(isDesktop);
      case 6:
        return _buildSettings(isDesktop);
      default:
        return _buildRecentForms(isDesktop);
    }
  }

  Widget _buildRecentForms(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent forms',
                style: TextStyle(
                  fontSize: isDesktop ? 24 : 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (isDesktop)
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.refresh),
                      onPressed: _loadUserForms,
                      tooltip: 'Refresh',
                    ),
                    IconButton(
                      icon: Icon(Icons.view_module_outlined),
                      onPressed: () {},
                      tooltip: 'Grid view',
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: 20),
          Text(
            'Start a new form',
            style: TextStyle(
              fontSize: isDesktop ? 18 : 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 120,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _showCreateDialog(),
                    borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_circle_outline,
                              size: 28,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Create New Form',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Start from templates or blank',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (isDesktop) ...[
                  SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const TemplateSelectionScreen(isQuiz: false),
                          ),
                        ).then((_) => _loadUserForms());
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.purple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.purple.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.explore_outlined,
                              size: 28,
                              color: Colors.purple,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Browse Templates',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              '12+ professional templates',
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: isDesktop ? 32 : 24),
          
          // Browse Templates Section
         /* Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Browse Templates',
                style: TextStyle(
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TemplateSelectionScreen(isQuiz: false),
                    ),
                  ).then((_) => _loadUserForms());
                },
                icon: Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: Color(0xFF1A73E8),
                ),
                label: Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF1A73E8),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),*/
          
          // Featured Templates Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFeaturedTemplateCard('Contact Information', 'Collect basic contact details', Icons.contact_page_outlined, Colors.green, 'contact_info', isDesktop),
                _buildFeaturedTemplateCard('Event Registration', 'Register attendees for events', Icons.event_outlined, Colors.orange, 'event_registration', isDesktop),
                _buildFeaturedTemplateCard('Customer Feedback', 'Collect satisfaction feedback', Icons.feedback_outlined, Colors.purple, 'customer_feedback', isDesktop),
                _buildFeaturedTemplateCard('Job Application', 'Collect job applications', Icons.work_outlined, Colors.indigo, 'job_application', isDesktop),
                _buildMoreTemplatesBrowseCard(isDesktop),
              ],
            ),
          ),
          SizedBox(height: isDesktop ? 32 : 24),
          
          Row(
            children: [
              Text(
                'Recent forms',
                style: TextStyle(
                  fontSize: isDesktop ? 18 : 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              Spacer(),
              if (!isDesktop)
                IconButton(
                  icon: Icon(Icons.refresh, size: 20),
                  onPressed: _loadUserForms,
                ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: _isLoadingForms
                ? Center(child: CircularProgressIndicator())
                : _userForms.isEmpty
                ? _buildEmptyState(isDesktop)
                : _buildFormsList(isDesktop),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDesktop) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.description_outlined,
            size: isDesktop ? 64 : 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          SizedBox(height: 12),
          Text(
            'No forms yet',
            style: TextStyle(
              fontSize: isDesktop ? 18 : 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Create your first form to get started',
            style: TextStyle(
              fontSize: isDesktop ? 13 : 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _showCreateDialog(),
            icon: Icon(Icons.add, color: Colors.white),
            label: Text('Create form', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1A73E8),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 20 : 16,
                vertical: isDesktop ? 10 : 8,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormsList(bool isDesktop) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return ListView.builder(
      itemCount: _userForms.length,
      itemBuilder: (context, index) {
        final form = _userForms[index];
        final formData = form.data() as Map<String, dynamic>;

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => formData['isQuiz'] == true
                      ? QuizBuilderScreen(quizId: form.id)
                      : FormBuilderScreen(formId: form.id),
                ),
              ).then((_) => _loadUserForms());
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: formData['isQuiz'] == true
                          ? Color(0xFF34A853).withOpacity(0.1)
                          : Color(0xFF1A73E8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      formData['isQuiz'] == true ? Icons.quiz_outlined : Icons.description_outlined,
                      color: formData['isQuiz'] == true ? Color(0xFF34A853) : Color(0xFF1A73E8),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formData['title'] ?? 'Untitled Form',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          formData['description'] ?? 'No description',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: formData['isPublished'] == true
                                    ? Colors.green[50]
                                    : Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                formData['isPublished'] == true ? 'Published' : 'Draft',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: formData['isPublished'] == true
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              '${(formData['questions'] as List?)?.length ?? 0} questions',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                              ),
                            ),
                            if (formData['isQuiz'] == true) ...[
                              SizedBox(width: 12),
                              Text(
                                '${formData['settings']?['totalPoints'] ?? 0} pts',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF34A853),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: formData['isStarred'] == true ? 'Remove from starred' : 'Add to starred',
                        icon: Icon(
                          formData['isStarred'] == true ? Icons.star : Icons.star_outline,
                          color: formData['isStarred'] == true ? Colors.amber : colorScheme.onSurface.withOpacity(0.6),
                        ),
                        onPressed: () {
                          _toggleStar(form.id, formData['isStarred'] == true);
                        },
                      ),
                      IconButton(
                        tooltip: 'Get link & QR',
                        icon: Icon(Icons.qr_code_2, color: colorScheme.onSurface.withOpacity(0.6)),
                        onPressed: () {
                          _showFormLinkDialog(form.id, formData['title'] ?? 'Untitled Form');
                        },
                      ),
                      PopupMenuButton(
                    icon: Icon(Icons.more_vert, color: colorScheme.onSurface.withOpacity(0.4)),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit, size: 16),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'share',
                        child: ListTile(
                          leading: Icon(Icons.share, size: 16),
                          title: Text('Share'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'duplicate',
                        child: ListTile(
                          leading: Icon(Icons.copy, size: 16),
                          title: Text('Duplicate'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'export',
                        child: ListTile(
                          leading: Icon(Icons.download_outlined, size: 16),
                          title: Text('Export to Excel'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, size: 16, color: Colors.red),
                          title: Text('Delete', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      // Add a small delay to prevent rapid successive triggers
                      await Future.delayed(Duration(milliseconds: 100));
                      switch (value) {
                        case 'edit':
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => formData['isQuiz'] == true
                                  ? QuizBuilderScreen(quizId: form.id)
                                  : FormBuilderScreen(formId: form.id),
                            ),
                          ).then((_) => _loadUserForms());
                          break;
                        case 'share':
                          _shareForm(form.id, formData['title'] ?? 'Untitled Form');
                          break;
                        case 'duplicate':
                          _duplicateForm(form.id);
                          break;
                        case 'export':
                          await _exportFormFromDashboard(
                            form.id,
                            formData['title'] ?? 'Untitled Form',
                          );
                          break;
                        case 'delete':
                          _deleteForm(form.id);
                          break;
                      }
                    },
                  ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Add create dialog method
  Future<void> _showCreateDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Create New', style: TextStyle(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCreateOption(
              'Form from Template',
              'Choose from professional templates',
              Icons.description_outlined,
              Colors.blue,
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TemplateSelectionScreen(isQuiz: false),
                ),
              ).then((_) => _loadUserForms()),
            ),
            const SizedBox(height: 12),
            _buildCreateOption(
              'Quiz from Template',
              'Choose from quiz templates',
              Icons.quiz_outlined,
              Colors.green,
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const TemplateSelectionScreen(isQuiz: true),
                ),
              ).then((_) => _loadUserQuizzes()),
            ),
            const SizedBox(height: 12),
            _buildCreateOption(
              'Blank Form',
              'Start from scratch',
              Icons.add_outlined,
              Colors.grey,
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FormBuilderScreen(),
                ),
              ).then((_) => _loadUserForms()),
            ),
            const SizedBox(height: 12),
            _buildCreateOption(
              'Blank Quiz',
              'Create a custom quiz',
              Icons.psychology_outlined,
              Colors.purple,
              () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QuizBuilderScreen(),
                ),
              ).then((_) => _loadUserQuizzes()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateOption(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Navigator.pop(context); // Close dialog first
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(String title, IconData icon, bool isBlank, bool isDesktop) {
    final colorScheme = Theme.of(context).colorScheme;
    final featuredTemplates = TemplateService.getFeaturedTemplates();
    
    // Handle different template types
    if (isBlank) {
      return Container(
        margin: EdgeInsets.only(right: isDesktop ? 16 : 0),
        child: InkWell(
          onTap: () => _showCreateDialog(),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: isDesktop ? 160 : null,
            height: isDesktop ? 200 : null,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(0xFF1A73E8),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFF1A73E8).withOpacity(0.1),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: isDesktop ? 48 : 36,
                        color: Color(0xFF1A73E8),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isDesktop ? 14 : 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Handle template-based cards
    FormTemplate? template;
    if (title.toLowerCase().contains('contact')) {
      template = TemplateService.getTemplateById('contact_info');
    } else if (title.toLowerCase().contains('registration')) {
      template = TemplateService.getTemplateById('event_registration');
    } else if (title.toLowerCase().contains('feedback')) {
      template = TemplateService.getTemplateById('customer_feedback');
    } else if (title.toLowerCase().contains('quiz')) {
      template = TemplateService.getTemplateById('quick_survey');
    }
    
    return Container(
      margin: EdgeInsets.only(right: isDesktop ? 16 : 0),
      child: InkWell(
        onTap: () {
          if (template != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => template!.questions.any((q) => q.isQuizQuestion)
                    ? QuizBuilderScreen(template: template)
                    : FormBuilderScreen(template: template),
              ),
            ).then((_) {
              _loadUserForms();
              _loadUserQuizzes();
            });
          } else {
            _showCreateDialog();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: isDesktop ? 160 : null,
          height: isDesktop ? 200 : null,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: template?.color.withOpacity(0.5) ?? Colors.grey[300]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: template?.color.withOpacity(0.1) ?? Colors.grey[100],
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Center(
                    child: Icon(
                      template?.icon ?? icon,
                      size: isDesktop ? 48 : 36,
                      color: template?.color ?? Colors.grey[600],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isDesktop ? 14 : 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (template != null) ...[
                      SizedBox(height: 4),
                      Text(
                        '${template!.questions.length} questions',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMoreTemplatesCard(bool isDesktop) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: EdgeInsets.only(right: isDesktop ? 16 : 0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TemplateSelectionScreen(isQuiz: false),
            ),
          ).then((_) => _loadUserForms());
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: isDesktop ? 160 : null,
          height: isDesktop ? 200 : null,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey[300]!,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: Stack(
                    children: [
                      // Background pattern of small icons
                      Positioned(
                        top: 20,
                        left: 20,
                        child: Icon(
                          Icons.description_outlined,
                          size: 16,
                          color: Colors.purple.withOpacity(0.3),
                        ),
                      ),
                      Positioned(
                        top: 30,
                        right: 30,
                        child: Icon(
                          Icons.quiz_outlined,
                          size: 14,
                          color: Colors.purple.withOpacity(0.3),
                        ),
                      ),
                      Positioned(
                        bottom: 30,
                        left: 30,
                        child: Icon(
                          Icons.feedback_outlined,
                          size: 12,
                          color: Colors.purple.withOpacity(0.3),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: Icon(
                          Icons.contact_page_outlined,
                          size: 18,
                          color: Colors.purple.withOpacity(0.3),
                        ),
                      ),
                      // Main icon in center
                      Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.purple.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            Icons.view_module_outlined,
                            size: isDesktop ? 24 : 20,
                            color: Colors.purple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  children: [
                    Text(
                      'More Templates',
                      style: TextStyle(
                        fontSize: isDesktop ? 14 : 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      '12+ templates',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedTemplateCard(String title, String description, IconData icon, Color color, String templateId, bool isDesktop) {
    final template = TemplateService.getTemplateById(templateId);
    
    return Container(
      width: isDesktop ? 200 : 180,
      height: 120,
      margin: EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: () {
          if (template != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FormBuilderScreen(template: template),
              ),
            ).then((_) => _loadUserForms());
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.08),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 16,
                      ),
                    ),
                    Spacer(),
                    Text(
                      '${template?.questions.length ?? 0}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                SizedBox(height: 3),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMoreTemplatesBrowseCard(bool isDesktop) {
    return Container(
      width: isDesktop ? 200 : 180,
      height: 120,
      margin: EdgeInsets.only(right: 16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const TemplateSelectionScreen(isQuiz: false),
            ),
          ).then((_) => _loadUserForms());
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A73E8).withOpacity(0.1),
                Color(0xFF7B1FA2).withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Color(0xFF1A73E8).withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF1A73E8).withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Color(0xFF1A73E8).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.explore_outlined,
                        color: Color(0xFF1A73E8),
                        size: 16,
                      ),
                    ),
                    Spacer(),
                    Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: Color(0xFF1A73E8),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'Explore All',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A73E8),
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Browse 12+ professional templates',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyForms(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'My Forms',
                style: TextStyle(
                  fontSize: isDesktop ? 24 : 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              Spacer(),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TemplateSelectionScreen(isQuiz: false),
                    ),
                  ).then((_) => _loadUserForms());
                },
                icon: Icon(
                  Icons.explore_outlined,
                  size: 16,
                  color: Color(0xFF1A73E8),
                ),
                label: Text(
                  'Browse Templates',
                  style: TextStyle(
                    color: Color(0xFF1A73E8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color(0xFF1A73E8)),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _loadUserForms,
                tooltip: 'Refresh',
              ),
            ],
          ),
          SizedBox(height: 24),
          Expanded(
            child: _isLoadingForms
                ? Center(child: CircularProgressIndicator())
                : _userForms.isEmpty
                ? _buildEmptyState(isDesktop)
                : _buildFormsList(isDesktop),
          ),
        ],
      ),
    );
  }

  Widget _buildMyQuizzes(bool isDesktop) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'My Quizzes',
                style: TextStyle(
                  fontSize: isDesktop ? 24 : 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Spacer(),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TemplateSelectionScreen(isQuiz: true),
                    ),
                  ).then((_) => _loadUserQuizzes());
                },
                icon: Icon(
                  Icons.explore_outlined,
                  size: 16,
                  color: Color(0xFF34A853),
                ),
                label: Text(
                  'Browse Templates',
                  style: TextStyle(
                    color: Color(0xFF34A853),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color(0xFF34A853)),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _loadUserQuizzes,
                tooltip: 'Refresh',
              ),
            ],
          ),
          SizedBox(height: 24),
          Expanded(
            child: _isLoadingQuizzes
                ? Center(child: CircularProgressIndicator())
                : _userQuizzes.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.quiz_outlined, size: isDesktop ? 64 : 48, color: colorScheme.onSurface.withOpacity(0.4)),
                  SizedBox(height: 12),
                  Text(
                    'No quizzes yet',
                    style: TextStyle(
                      fontSize: isDesktop ? 18 : 16,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Create your first quiz to get started',
                    style: TextStyle(
                      fontSize: isDesktop ? 13 : 11,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateDialog(),
                    icon: Icon(Icons.add, color: Colors.white),
                    label: Text('Create quiz', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF34A853),
                      padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 20 : 16,
                        vertical: isDesktop ? 10 : 8,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            )
                : _buildQuizzesList(isDesktop),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizzesList(bool isDesktop) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return ListView.builder(
      itemCount: _userQuizzes.length,
      itemBuilder: (context, index) {
        final quiz = _userQuizzes[index];
        final quizData = quiz.data() as Map<String, dynamic>;

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => QuizBuilderScreen(quizId: quiz.id),
                ),
              ).then((_) => _loadUserQuizzes());
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.1),
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
                  // Quiz Title
                  Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      quizData['title'] ?? 'Untitled Quiz',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: quizData['isPublished'] == true
                              ? Colors.green[50]
                              : Colors.orange[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          quizData['isPublished'] == true ? 'Published' : 'Draft',
                          style: TextStyle(
                            fontSize: 12,
                            color: quizData['isPublished'] == true
                                ? Colors.green[700]
                                : Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                        Text(
                          '${(quizData['questions'] as List?)?.length ?? 0} questions',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      SizedBox(width: 12),
                      Text(
                        '${quizData['settings']?['totalPoints'] ?? 0} pts',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF34A853),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 12),
                      Switch(
                        value: quizData['isPublished'] == true,
                        onChanged: (val) async {
                          await FirebaseFirestore.instance
                            .collection('forms')
                            .doc(quiz.id)
                            .update({'isPublished': val});
                          // Update the UI after successful Firestore update
                          _loadUserQuizzes();
                        },
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.orange,
                        inactiveTrackColor: Colors.orange[200],
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        tooltip: quizData['isStarred'] == true ? 'Remove from starred' : 'Add to starred',
                        icon: Icon(
                          quizData['isStarred'] == true ? Icons.star : Icons.star_outline,
                          color: quizData['isStarred'] == true ? Colors.amber : colorScheme.onSurface.withOpacity(0.6),
                          size: 20,
                        ),
                        onPressed: () {
                          _toggleStar(quiz.id, quizData['isStarred'] == true);
                        },
                        padding: EdgeInsets.all(8),
                        constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                      ),
                      Spacer(),
                      IconButton(
                        tooltip: 'Get link & QR',
                        icon: Icon(Icons.qr_code_2, color: colorScheme.onSurface.withOpacity(0.6)),
                        onPressed: () async {
                          final link = _buildQuizLink(quiz.id);
                          final isPublished = quizData['isPublished'] == true;
                          await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              title: Text('Share "${quizData['title'] ?? 'Untitled Quiz'}"'),
                              content: SizedBox(
                                width: 300,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    QrImageView(data: link, size: 180),
                                    SizedBox(height: 12),
                                    SelectableText(link, style: TextStyle(fontSize: 12)),
                                    SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(isPublished ? Icons.check_circle : Icons.info_outline, color: isPublished ? Colors.green : Colors.orange, size: 18),
                                        SizedBox(width: 6),
                                        Text(isPublished ? 'Published' : 'Draft', style: TextStyle(fontWeight: FontWeight.w500, color: isPublished ? Colors.green : Colors.orange)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
                              ],
                            ),
                          );
                        },
                      ),
                      PopupMenuButton(
                        icon: Icon(Icons.more_vert, color: colorScheme.onSurface.withOpacity(0.4)),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit, size: 16),
                              title: Text('Edit'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'share',
                            child: ListTile(
                              leading: Icon(Icons.share, size: 16),
                              title: Text('Share'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'duplicate',
                            child: ListTile(
                              leading: Icon(Icons.copy, size: 16),
                              title: Text('Duplicate'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              leading: Icon(Icons.delete, size: 16, color: Colors.red),
                              title: Text('Delete', style: TextStyle(color: Colors.red)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => QuizBuilderScreen(quizId: quiz.id),
                              ),
                            ).then((_) => _loadUserQuizzes());
                          } else if (value == 'share') {
                            _shareForm(quiz.id, quizData['title'] ?? 'Untitled Quiz');
                          } else if (value == 'duplicate') {
                            _duplicateForm(quiz.id);
                          } else if (value == 'delete') {
                            _deleteForm(quiz.id);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _buildQuizLink(String quizId) {
    if (kIsWeb) {
      final origin = html.window.location.origin;
      return '$origin/quizzes/$quizId';
    }
    return 'https://yourdomain.com/quizzes/$quizId';
  }
  Widget _buildStarred(bool isDesktop) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Starred Forms',
                style: TextStyle(
                  fontSize: isDesktop ? 24 : 20,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _loadStarredForms,
                tooltip: 'Refresh',
              ),
            ],
          ),
          SizedBox(height: 24),
          Expanded(
            child: _isLoadingStarredForms
                ? Center(child: CircularProgressIndicator())
                : _starredForms.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_outline,
                    size: isDesktop ? 64 : 48,
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'No starred forms yet',
                    style: TextStyle(
                      fontSize: isDesktop ? 18 : 16,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Star your favorite forms to see them here',
                    style: TextStyle(
                      fontSize: isDesktop ? 13 : 11,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            )
                : _buildStarredFormsList(isDesktop),
          ),
        ],
      ),
    );
  }

  Widget _buildStarredFormsList(bool isDesktop) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return ListView.builder(
      itemCount: _starredForms.length,
      itemBuilder: (context, index) {
        final form = _starredForms[index];
        final formData = form.data() as Map<String, dynamic>;

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => formData['isQuiz'] == true
                      ? QuizBuilderScreen(quizId: form.id)
                      : FormBuilderScreen(formId: form.id),
                ),
              ).then((_) => _loadStarredForms());
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formData['title'] ?? 'Untitled Form',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          formData['description'] ?? 'No description',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: formData['isQuiz'] == true
                                    ? Color(0xFF34A853).withOpacity(0.1)
                                    : Color(0xFF1A73E8).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                formData['isQuiz'] == true ? 'Quiz' : 'Form',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: formData['isQuiz'] == true
                                      ? Color(0xFF34A853)
                                      : Color(0xFF1A73E8),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: formData['isPublished'] == true
                                    ? Colors.green[50]
                                    : Colors.orange[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                formData['isPublished'] == true ? 'Published' : 'Draft',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: formData['isPublished'] == true
                                      ? Colors.green[700]
                                      : Colors.orange[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              '${(formData['questions'] as List?)?.length ?? 0} questions',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Remove from starred',
                        icon: Icon(
                          Icons.star,
                          color: Colors.amber,
                        ),
                        onPressed: () {
                          _toggleStar(form.id, true);
                        },
                      ),
                      IconButton(
                        tooltip: 'Get link & QR',
                        icon: Icon(Icons.qr_code_2, color: colorScheme.onSurface.withOpacity(0.6)),
                        onPressed: () {
                          _showFormLinkDialog(form.id, formData['title'] ?? 'Untitled Form');
                        },
                      ),
                      PopupMenuButton(
                        icon: Icon(Icons.more_vert, color: colorScheme.onSurface.withOpacity(0.4)),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(Icons.edit, size: 16),
                              title: Text('Edit'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'share',
                            child: ListTile(
                              leading: Icon(Icons.share, size: 16),
                              title: Text('Share'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'duplicate',
                            child: ListTile(
                              leading: Icon(Icons.copy, size: 16),
                              title: Text('Duplicate'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'unstar',
                            child: ListTile(
                              leading: Icon(Icons.star_outline, size: 16, color: Colors.amber),
                              title: Text('Remove from starred', style: TextStyle(color: Colors.amber)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                        onSelected: (value) async {
                          await Future.delayed(Duration(milliseconds: 100));
                          switch (value) {
                            case 'edit':
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => formData['isQuiz'] == true
                                      ? QuizBuilderScreen(quizId: form.id)
                                      : FormBuilderScreen(formId: form.id),
                                ),
                              ).then((_) => _loadStarredForms());
                              break;
                            case 'share':
                              _shareForm(form.id, formData['title'] ?? 'Untitled Form');
                              break;
                            case 'duplicate':
                              _duplicateForm(form.id);
                              break;
                            case 'unstar':
                              _toggleStar(form.id, true);
                              break;
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrash(bool isDesktop) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Trash',
                style: TextStyle(
                  fontSize: isDesktop ? 24 : 20,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: _loadTrashedForms,
                tooltip: 'Refresh',
              ),
              if (_trashedForms.isNotEmpty)
                TextButton.icon(
                  onPressed: _emptyTrash,
                  icon: Icon(Icons.delete_forever, color: Colors.red),
                  label: Text('Empty Trash', style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
          SizedBox(height: 24),
          Expanded(
            child: _isLoadingTrashedForms
                ? Center(child: CircularProgressIndicator())
                : _trashedForms.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: isDesktop ? 64 : 48,
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Trash is empty',
                    style: TextStyle(
                      fontSize: isDesktop ? 18 : 16,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Deleted forms will appear here',
                    style: TextStyle(
                      fontSize: isDesktop ? 13 : 11,
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            )
                : _buildTrashedFormsList(isDesktop),
          ),
        ],
      ),
    );
  }

  Widget _buildTrashedFormsList(bool isDesktop) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return ListView.builder(
      itemCount: _trashedForms.length,
      itemBuilder: (context, index) {
        final form = _trashedForms[index];
        final formData = form.data() as Map<String, dynamic>;
        final deletedAt = DateTime.parse(formData['deletedAt']);

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Colors.red[600],
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formData['title'] ?? 'Untitled Form',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Deleted ${_getTimeAgo(formData['deletedAt'] as String)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red[600],
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '${(formData['questions'] as List?)?.length ?? 0} questions',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.restore, color: Colors.green[600]),
                      onPressed: () => _restoreForm(form.id),
                      tooltip: 'Restore',
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_forever, color: Colors.red[600]),
                      onPressed: () => _permanentlyDeleteForm(form.id),
                      tooltip: 'Delete Forever',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnalytics(bool isDesktop) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Analytics',
            style: TextStyle(
              fontSize: isDesktop ? 24 : 20,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 12),
          isDesktop ? Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                  );
                },
                icon: Icon(Icons.bar_chart_rounded),
                label: Text('Visual Analytics'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _loadAnalytics,
                icon: _isLoadingAnalytics
                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
                    : Icon(Icons.refresh),
                label: Text(_isLoadingAnalytics ? 'Loading...' : 'Refresh Data'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Theme.of(context).colorScheme.onSecondary,
                ),
              ),
              SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _formAnalytics.isEmpty ? null : _exportAnalyticsToExcel,
                icon: Icon(Icons.file_download_outlined),
                label: Text('Export Excel'),
              ),
            ],
          ) : Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AnalyticsScreen()),
                    );
                  },
                  icon: Icon(Icons.bar_chart_rounded),
                  label: Text('Visual Analytics'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _loadAnalytics,
                  icon: _isLoadingAnalytics
                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Theme.of(context).colorScheme.onPrimary))
                      : Icon(Icons.refresh),
                  label: Text(_isLoadingAnalytics ? 'Loading...' : 'Refresh Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _formAnalytics.isEmpty ? null : _exportAnalyticsToExcel,
                  icon: Icon(Icons.file_download_outlined),
                  label: Text('Export Excel'),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          isDesktop
              ? Row(
            children: [
              Expanded(child: _buildAnalyticsCard('Total Forms', '${_userForms.length}', Icons.description, Color(0xFF1A73E8))),
              SizedBox(width: 16),
              Expanded(child: _buildAnalyticsCard('Total Quizzes', '${_userQuizzes.length}', Icons.quiz, Color(0xFF34A853))),
              SizedBox(width: 16),
              Expanded(child: _buildAnalyticsCard('Active Forms', '${_userForms.where((f) => (f.data() as Map)['isPublished'] == true).length}', Icons.trending_up, Color(0xFFFF9800))),
            ],
          )
              : Column(
            children: [
              _buildAnalyticsCard('Total Forms', '${_userForms.length}', Icons.description, Color(0xFF1A73E8)),
              SizedBox(height: 12),
              _buildAnalyticsCard('Total Quizzes', '${_userQuizzes.length}', Icons.quiz, Color(0xFF34A853)),
              SizedBox(height: 12),
              _buildAnalyticsCard('Active Forms', '${_userForms.where((f) => (f.data() as Map)['isPublished'] == true).length}', Icons.trending_up, Color(0xFFFF9800)),
            ],
          ),
          SizedBox(height: 24),
          Expanded(
            child: _isLoadingAnalytics
                ? Center(child: CircularProgressIndicator())
                : _formAnalytics.isEmpty
                    ? Center(child: Text('No analytics yet. Click Refresh Analytics.'))
                    : ListView.builder(
                        itemCount: _formAnalytics.length,
                        itemBuilder: (context, index) {
                          final fa = _formAnalytics[index];
                          return Container(
                            margin: EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.insert_chart_outlined, color: Color(0xFF1A73E8)),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        fa.title,
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Chip(label: Text('${fa.responseCount} responses')),
                                  ],
                                ),
                                if (fa.numericAverages.isNotEmpty) ...[
                                  SizedBox(height: 8),
                                  Text('Averages for numeric questions:', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6))),
                                  SizedBox(height: 4),
                                  ...fa.numericAverages.entries.map((e) => Row(
                                        children: [
                                          Expanded(child: Text(e.key)),
                                          Text(e.value.toStringAsFixed(2)),
                                        ],
                                      )),
                                ] else ...[
                                  SizedBox(height: 8),
                                  Text('No numeric questions to average.', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6))),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
              Icon(icon, color: color, size: 24),
              Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings(bool isDesktop) {
    return Padding(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Text(
                'Settings',
                style: TextStyle(
                  fontSize: isDesktop ? 24 : 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
          SizedBox(height: 24),
          _buildSettingsCard(
            'Account',
            'Manage your account settings',
            Icons.person_outline,
                _openAccountSettings,
          ),
          _buildSettingsCard(
            'Notifications',
            'Configure notification preferences',
            Icons.notifications_outlined,
                _openNotificationSettings,
          ),
          _buildSettingsCard(
            'Appearance',
            'Light or Dark mode',
            Icons.brightness_6_outlined,
                _openAppearanceSettings,
          ),
          _buildSettingsCard(
            'Privacy',
            'Privacy and data settings',
            Icons.privacy_tip_outlined,
                _openPrivacySettings,
          ),
          _buildSettingsCard(
            'About',
            'App information and support',
            Icons.info_outline,
                _openAboutDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 24),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
            ],
          ),
        ),
      ),
    );
  }

  Future<Map<String, dynamic>?> _loadCurrentUserDoc() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return doc.data();
  }

  Future<void> _openAccountSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final data = await _loadCurrentUserDoc() ?? {};
    final nameController = TextEditingController(text: (data['name'] ?? user.displayName ?? '').toString());

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Account Settings'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Display name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  SizedBox(height: 12),
                  TextField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                      hintText: user.email ?? '',
                    ),
                  ),
                  SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () async {
                        if (user.email == null) return;
                        try {
                          await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Password reset email sent to ${user.email}')),
                          );
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to send reset email: $e')),
                          );
                        }
                      },
                      icon: Icon(Icons.lock_reset),
                      label: Text('Send password reset email'),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = nameController.text.trim();
                try {
                  if (newName.isNotEmpty) {
                    await user.updateDisplayName(newName);
                    await user.reload();
                    final refreshed = FirebaseAuth.instance.currentUser;
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
                      'name': newName,
                      'email': refreshed?.email ?? user.email ?? '',
                      'updatedAt': DateTime.now().toIso8601String(),
                    }, SetOptions(merge: true));
                  }
                  if (!mounted) return;
                  final rootCtx = _scaffoldKey.currentContext;
                  Navigator.pop(context);
                  if (rootCtx != null) {
                    ScaffoldMessenger.of(rootCtx).showSnackBar(
                      SnackBar(content: Text('Account updated successfully')),
                    );
                  }
                  setState(() {});
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update account: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1A73E8)),
              child: Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openNotificationSettings() async {
    final settingsNotifier = Provider.of<SettingsNotifier>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    bool emailPref = settingsNotifier.emailNotifications;
    bool appPref = settingsNotifier.pushNotifications;
    bool soundPref = settingsNotifier.soundEnabled;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.notifications_outlined, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text('Notifications'),
            ],
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    value: emailPref,
                    onChanged: (v) => setStateDialog(() => emailPref = v),
                    title: Text('Email notifications'),
                    subtitle: Text('Receive updates by email'),
                    secondary: Icon(Icons.email_outlined),
                  ),
                  SwitchListTile(
                    value: appPref,
                    onChanged: (v) => setStateDialog(() => appPref = v),
                    title: Text('Push notifications'),
                    subtitle: Text('Show notifications in the app'),
                    secondary: Icon(Icons.notifications_active_outlined),
                  ),
                  SwitchListTile(
                    value: soundPref,
                    onChanged: (v) => setStateDialog(() => soundPref = v),
                    title: Text('Sound'),
                    subtitle: Text('Play sound for notifications'),
                    secondary: Icon(Icons.volume_up_outlined),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await settingsNotifier.setEmailNotifications(emailPref);
                  await settingsNotifier.setPushNotifications(appPref);
                  await settingsNotifier.setSoundEnabled(soundPref);
                  
                  setState(() {
                    _notifyEmail = emailPref;
                    _notifyApp = appPref;
                  });
                  
                  if (!mounted) return;
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Notification preferences saved'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to save preferences: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openPrivacySettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Privacy and Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.download_outlined),
                title: Text('Download my data'),
                subtitle: Text('Export basic account information'),
                onTap: () async {
                  final rootCtx = _scaffoldKey.currentContext;
                  Navigator.pop(context);
                  if (rootCtx != null) {
                    ScaffoldMessenger.of(rootCtx).showSnackBar(
                      SnackBar(content: Text('Data export queued')),
                    );
                  }
                },
              ),
              Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.delete_outline, color: Colors.red),
                title: Text('Delete account', style: TextStyle(color: Colors.red)),
                subtitle: Text('Permanently delete your account'),
                onTap: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Delete account?'),
                      content: Text('This will permanently delete your account. This action cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel')),
                        TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Delete', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      // Best-effort mark forms as deleted
                      final forms = await FirebaseFirestore.instance
                          .collection('forms')
                          .where('createdBy', isEqualTo: user.uid)
                          .get();
                      final batch = FirebaseFirestore.instance.batch();
                      for (final f in forms.docs) {
                        batch.update(f.reference, {
                          'isDeleted': true,
                          'deletedAt': DateTime.now().toIso8601String(),
                          'updatedAt': DateTime.now().toIso8601String(),
                        });
                      }
                      await batch.commit();

                      // Delete user profile doc (optional, keep for audit if needed)
                      await FirebaseFirestore.instance.collection('users').doc(user.uid).delete().catchError((_) {});

                      await user.delete();
                      if (!mounted) return;
                      final rootCtx = _scaffoldKey.currentContext;
                      if (rootCtx != null) {
                        ScaffoldMessenger.of(rootCtx).showSnackBar(
                          SnackBar(content: Text('Account deleted')),
                        );
                      }
                    } catch (e) {
                      if (!mounted) return;
                      final rootCtx = _scaffoldKey.currentContext;
                      if (rootCtx != null) {
                        ScaffoldMessenger.of(rootCtx).showSnackBar(
                          SnackBar(content: Text('Deletion failed: $e. Please re-login and try again.')),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openAboutDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text('About'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Prem's Form Builder",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Version 1.0.0',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 20),
              Text(
                'A Mvitians Form builder app.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 16),
              Divider(),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.email_outlined, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  SizedBox(width: 8),
                  Text('Support: premraaj002@gmail.com'),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.language_outlined, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  SizedBox(width: 8),
                  Text('Developed by Premraaj from ECE dept.'),
                ],
              ),
              SizedBox(height: 16),
              Text(
                '© 2025 Prem\'s Form Builder. All rights reserved.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openAppearanceSettings() async {
    final themeNotifier = Provider.of<ThemeNotifier>(context, listen: false);
    String currentTheme = themeNotifier.themeModeString;
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.palette_outlined, color: Theme.of(context).colorScheme.primary),
              SizedBox(width: 8),
              Text('Appearance'),
            ],
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Choose your preferred theme',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildThemeOption(
                    context,
                    'Light',
                    'Always use light theme',
                    Icons.light_mode,
                    'light',
                    currentTheme,
                    (value) => setStateDialog(() => currentTheme = value),
                  ),
                  SizedBox(height: 8),
                  _buildThemeOption(
                    context,
                    'Dark',
                    'Always use dark theme',
                    Icons.dark_mode,
                    'dark',
                    currentTheme,
                    (value) => setStateDialog(() => currentTheme = value),
                  ),
                  SizedBox(height: 8),
                  _buildThemeOption(
                    context,
                    'System',
                    'Follow system settings',
                    Icons.brightness_auto,
                    'system',
                    currentTheme,
                    (value) => setStateDialog(() => currentTheme = value),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await themeNotifier.setThemeFromString(currentTheme);
                  
                  if (!mounted) return;
                  Navigator.pop(context);
                  
                  String displayName = currentTheme == 'system' 
                      ? 'System Default' 
                      : currentTheme.substring(0, 1).toUpperCase() + currentTheme.substring(1);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Theme changed to $displayName'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to update theme: $e'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                }
              },
              child: Text('Apply'),
            ),
          ],
        );
      },
    );
  }
  
  Widget _buildThemeOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    String value,
    String currentValue,
    ValueChanged<String> onChanged,
  ) {
    final isSelected = currentValue == value;
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? colorScheme.primary : colorScheme.outline.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
        color: isSelected ? colorScheme.primaryContainer.withOpacity(0.3) : null,
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: currentValue,
        onChanged: (v) => onChanged(v ?? value),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        title: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? colorScheme.primary.withOpacity(0.8) : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        activeColor: colorScheme.primary,
      ),
    );
  }

}
