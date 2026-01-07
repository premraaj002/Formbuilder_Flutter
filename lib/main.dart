import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_links/app_links.dart'; // For initial link handling (web/mobile)
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb; // For platform detection
import 'package:universal_html/html.dart' as html; // For web-specific URL parsing
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'theme_notifier.dart';
import 'theme/app_theme.dart';
import 'providers/settings_notifier.dart';
import 'auth_wrapper.dart';
import 'screens/form_fill_screen.dart'; // Import the form fill screen
import 'screens/public_form_screen.dart'; // Import the public form screen
import 'screens/public_quiz_screen.dart'; // Import the public quiz screen
import 'screens/login_page.dart'; // Import the login page
import 'screens/student_login.dart'; // Import the student login page
import 'screens/password_reset_confirmation_page.dart'; // Password reset confirm
import 'screens/landing_page.dart'; // Import the landing page

// Global navigator key for deep link navigation1
GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>(); // For deep link navigation

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firestore
  FirebaseFirestore.instance.settings = Settings(
    persistenceEnabled: true,
  );

  // Initialize theme notifier
  final themeNotifier = ThemeNotifier();
  await themeNotifier.initialize();
  
  // Initialize settings notifier
  final settingsNotifier = SettingsNotifier();
  await settingsNotifier.initialize();
  
  // Sync SettingsNotifier with ThemeNotifier for compatibility
  settingsNotifier.setDarkMode(themeNotifier.themeMode == ThemeMode.dark);

  initDeepLinks(); // Set up deep link handling

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => themeNotifier),
      ChangeNotifierProvider(create: (_) => settingsNotifier),
    ],
    child: const MyApp(),
  ));
}

void initDeepLinks() {
  if (kIsWeb) {
    // Web: Parse current URL for deep links
    final currentUrl = html.window.location.href;
    if (currentUrl.contains('forms/') || currentUrl.contains('quizzes/') || currentUrl.contains('?')) {
      handleLink(currentUrl);
    }
  } else {
    // Mobile/desktop: Use app_links
    final appLinks = AppLinks();
    
    // Get initial link when app is launched
    appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        handleLink(uri.toString());
      }
    });

    // Handle incoming links while app is running (mobile only)
    appLinks.uriLinkStream.listen(
      (uri) => handleLink(uri.toString()),
      onError: (err) => print('Deep link error: $err'),
    );
  }
}

void handleLink(String? link) { // Changed to String? for null safety
  if (link == null || link.isEmpty) return; // Early return for null/empty links

  try {
    final uri = Uri.parse(link);
    String? formId = uri.queryParameters['formId'];
    String? quizId = uri.queryParameters['quizId'];
    final String? mode = uri.queryParameters['mode'];
    final String? oobCode = uri.queryParameters['oobCode'];
    
    // Also support path style: /forms/{formId} or /quizzes/{quizId}
    if (uri.pathSegments.isNotEmpty) {
      final segments = uri.pathSegments;
      final formsIdx = segments.indexOf('forms');
      final quizzesIdx = segments.indexOf('quizzes');
      
      if (formsIdx != -1 && formsIdx + 1 < segments.length) {
        formId = segments[formsIdx + 1];
      } else if (quizzesIdx != -1 && quizzesIdx + 1 < segments.length) {
        quizId = segments[quizzesIdx + 1];
      }
    }
    
    if (formId != null && formId.isNotEmpty) {
      final String nonNullFormId = formId;
      print('Opening form: $formId');
      // Delay navigation slightly to ensure app is ready (especially on web)
      Future.delayed(Duration(milliseconds: 500), () {
        if (navigatorKey.currentState?.mounted ?? false) {
          navigatorKey.currentState?.pushReplacement(MaterialPageRoute(
            builder: (context) => PublicFormScreen(formId: nonNullFormId),
          ));
        } else {
          print('Navigator not ready for deep link navigation');
        }
      });
    } else if (quizId != null && quizId.isNotEmpty) {
      final String nonNullQuizId = quizId;
      print('Opening quiz: $quizId');
      // Delay navigation slightly to ensure app is ready (especially on web)
      Future.delayed(Duration(milliseconds: 500), () {
        if (navigatorKey.currentState?.mounted ?? false) {
          navigatorKey.currentState?.pushReplacement(MaterialPageRoute(
            builder: (context) => PublicQuizScreen(quizId: nonNullQuizId),
          ));
        } else {
          print('Navigator not ready for deep link navigation');
        }
      });
    } else if (mode == 'resetPassword' && oobCode != null && oobCode.isNotEmpty) {
      print('Opening password reset with oobCode');
      Future.delayed(Duration(milliseconds: 500), () {
        if (navigatorKey.currentState?.mounted ?? false) {
          navigatorKey.currentState?.pushReplacement(MaterialPageRoute(
            builder: (context) => PasswordResetConfirmationPage(oobCode: oobCode),
          ));
        } else {
          print('Navigator not ready for deep link navigation');
        }
      });
    }
  } catch (e) {
    print('Error parsing deep link: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  
  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    
    // Theme is handled by ThemeNotifier - no need to sync here
    
    return MaterialApp(
      title: 'Formbuilder',
      debugShowCheckedModeBanner: false,
      themeMode: themeNotifier.themeMode,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      navigatorKey: navigatorKey,
      home: LandingPage(),
      // Named routes for easier navigation
      routes: {
        '/auth': (context) => AuthWrapper(),
        '/form-fill': (context) => FormFillScreen(formId: ModalRoute.of(context)!.settings.arguments as String),
        '/public-form': (context) => PublicFormScreen(formId: ModalRoute.of(context)!.settings.arguments as String),
        '/public-quiz': (context) => PublicQuizScreen(quizId: ModalRoute.of(context)!.settings.arguments as String),
        '/login': (context) => LoginScreen(),
        '/student-login': (context) => StudentLoginScreen(),
        '/landing': (context) => LandingPage(),
      },
    );
  }
}









