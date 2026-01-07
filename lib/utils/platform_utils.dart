import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class PlatformUtils {
  // Platform detection
  static bool get isWeb => kIsWeb;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isWindows => !kIsWeb && Platform.isWindows;
  static bool get isLinux => !kIsWeb && Platform.isLinux;
  static bool get isMacOS => !kIsWeb && Platform.isMacOS;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isMobile => isAndroid || isIOS;
  static bool get isDesktop => isWindows || isLinux || isMacOS;
  
  // Platform-specific configurations
  static String get platformName {
    if (isWeb) return 'Web';
    if (isAndroid) return 'Android';
    if (isWindows) return 'Windows';
    if (isLinux) return 'Linux';
    if (isMacOS) return 'macOS';
    if (isIOS) return 'iOS';
    return 'Unknown';
  }
  
  // File system support
  static bool get supportsFileSystem => !isWeb;
  
  // Download support
  static bool get supportsDownloads => isDesktop || isAndroid;
  
  // Share support
  static bool get supportsNativeShare => isMobile;
  
  // Window management
  static bool get supportsWindowManagement => isDesktop;
  
  // Deep links support
  static bool get supportsDeepLinks => true; // All platforms support deep links
  
  // Permission support
  static bool get needsPermissions => isAndroid;
  
  // Local storage paths
  static bool get hasDocumentsDirectory => supportsFileSystem;
  
  // Default window size for desktop platforms
  static const double defaultWindowWidth = 1200;
  static const double defaultWindowHeight = 800;
  static const double minWindowWidth = 800;
  static const double minWindowHeight = 600;
  
  // Platform-specific app configurations
  static Map<String, dynamic> get appConfig {
    return {
      'platform': platformName,
      'isWeb': isWeb,
      'isMobile': isMobile,
      'isDesktop': isDesktop,
      'supportsFileSystem': supportsFileSystem,
      'supportsDownloads': supportsDownloads,
      'supportsNativeShare': supportsNativeShare,
      'supportsWindowManagement': supportsWindowManagement,
      'needsPermissions': needsPermissions,
    };
  }
}
