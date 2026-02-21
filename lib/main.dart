import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; //للتحكم في بعض خصائص النظام مثل اتجاه الشاشة ومظهر شريط الحالة.
import 'package:provider/provider.dart'; //لإدارة حالة التطبيق.
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; //: للتعامل مع الإشعارات الفورية (FCM - Firebase Cloud Messaging).
import 'package:secure_application/secure_application.dart';
import 'package:screen_protector/screen_protector.dart';

import 'firebase_options.dart';
// Controllers
import 'controllers/auth_controller.dart';
import 'controllers/chat_controller.dart';
import 'controllers/contact_controller.dart';
import 'controllers/profile_controller.dart';
import 'controllers/settings_controller.dart';

// Services
import 'services/notification_service.dart';
import 'services/security_service.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/signin_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/contact_screen.dart';
import 'screens/contact_info_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';

// Utils
import 'utils/constants.dart';

/// Global notification service instance
final notificationService = NotificationService();

void main() async {
  //  تهيئة Flutter  قبل البدء بأي عمل
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase with options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  //  تحديد اتجاه الشاشة
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  //  تخصيص مظهر شريط حالة النظام (شريط البطارية والوقت)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Set up FCM background message handler
  //  تعيين دالة لمعالجة الإشعارات التي تصل أثناء إغلاق التطبيق
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize notification service
  // : استدعاء دالة لتهيئة خدمة الإشعارات المحلية والتعامل مع الإشعارات الفورية
  await notificationService.initialize();

  // ==================== Security Checks ====================
  // فحص الأمان: Root/Jailbreak + Emulator + Debug Mode
  // في وضع Debug يتم تخطي الفحوصات للسماح بالتطوير
  final securityResult = await SecurityService.runSecurityChecks();

  // إخفاء الشاشة عند الخروج للخلفية (حماية المحتوى في recent apps)
  // ملاحظة: screen_protector يعمل فقط على Android/iOS — على Web يتم تخطيه
  try {
    await ScreenProtector.protectDataLeakageWithBlur();
  } catch (e) {
    debugPrint('ScreenProtector not supported on this platform: $e');
  }

  // Run the app
  runApp(YemenChatApp(securityResult: securityResult));
}

/// Main application widget
class YemenChatApp extends StatelessWidget {
  final SecurityCheckResult securityResult;

  const YemenChatApp({super.key, required this.securityResult});

  @override
  Widget build(BuildContext context) {
    // ==================== Security Violation Screen ====================
    // إذا تم اكتشاف انتهاك أمني، يعرض شاشة حمراء ويمنع التشغيل
    if (!securityResult.isSafe) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.security, color: Colors.red, size: 80),
                  const SizedBox(height: 24),
                  const Text(
                    'Security Violation Detected!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    securityResult.violationType ?? 'Unknown Violation',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'App will not run.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ==================== Normal App ====================
    // التطبيق آمن → يعمل بشكل طبيعي مع SecureApplication لإخفاء المحتوى عند الخروج للخلفية
    return SecureApplication(
      nativeRemoveDelay: 800,
      onNeedUnlock: (secureApplicationController) async {
        // إعادة فتح التطبيق بدون قفل إضافي
        secureApplicationController?.unlock();
        return SecureApplicationAuthenticationStatus.SUCCESS;
      },
      child: MultiProvider(
        providers: [
          // Auth controller - manages user authentication state
          ChangeNotifierProvider(create: (_) => AuthController()),

          // Settings controller - manages app settings
          ChangeNotifierProvider(create: (_) => SettingsController()),

          // Chat controller - manages chats and messages
          ChangeNotifierProvider(create: (_) => ChatController()),

          // Contact controller - manages contacts and favorites
          ChangeNotifierProvider(create: (_) => ContactController()),

          // Profile controller - manages user profile
          ChangeNotifierProvider(create: (_) => ProfileController()),
        ],
        child: Consumer<SettingsController>(
          builder: (context, settings, _) {
            return MaterialApp(
              // App info
              title: kAppName,
              debugShowCheckedModeBanner: false,

              // Theme configuration - Default to Light Mode
              theme: _buildLightTheme(),
              darkTheme: _buildDarkTheme(),
              themeMode: settings.themeMode,

              // Initial route
              initialRoute: kRouteSplash,

              // Route generation
              onGenerateRoute: _generateRoute,

              // SecureGate يجب أن يكون داخل MaterialApp لأنه يحتاج Directionality
              builder: (context, child) {
                return SecureGate(
                  blurr: 20,
                  opacity: 0.6,
                  lockedBuilder: (context, secureNotifier) {
                    return const Scaffold(
                      backgroundColor: Colors.black,
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              color: Colors.white54,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Screen Hidden for Security',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: child ?? const SizedBox.shrink(),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// Build enhanced Material 3 Light theme
  ThemeData _buildLightTheme() {
    // Define color scheme from seed color
    final colorScheme = ColorScheme.fromSeed(
      seedColor: kPrimaryColor,
      brightness: Brightness.light,
    );

    return ThemeData(
      // Material 3
      useMaterial3: true,
      brightness: Brightness.light,

      // Color scheme
      colorScheme: colorScheme,
      primaryColor: kPrimaryColor,
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),

      // Typography
      textTheme: TextTheme(
        // Display styles
        displayLarge: const TextStyle(
          fontSize: 57,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
        ),
        displayMedium: const TextStyle(
          fontSize: 45,
          fontWeight: FontWeight.w400,
        ),
        displaySmall: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w400,
        ),

        // Headline styles
        headlineLarge: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
        ),
        headlineMedium: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w400,
        ),
        headlineSmall: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
        ),

        // Title styles
        titleLarge: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
        ),
        titleMedium: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
        ),
        titleSmall: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),

        // Body styles
        bodyLarge: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
        ),
        bodyMedium: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
        ),
        bodySmall: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
        ),

        // Label styles
        labelLarge: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
        ),
        labelMedium: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
        labelSmall: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
        ),
      ),

      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          letterSpacing: 0.15,
        ),
        iconTheme: const IconThemeData(color: Colors.white, size: 24),
        actionsIconTheme: const IconThemeData(color: Colors.white, size: 24),
      ),

      // Card theme
      cardTheme: CardTheme(
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusMD),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Navigation bar theme
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 3,
        height: 72,
        indicatorColor: kPrimaryColor.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: kPrimaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              letterSpacing: 0.5,
            );
          }
          return TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            letterSpacing: 0.5,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: kPrimaryColor, size: 24);
          }
          return IconThemeData(color: Colors.grey.shade600, size: 24);
        }),
      ),

      // Button themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: kPrimaryColor.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusMD),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: kPrimaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusSM),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kPrimaryColor,
          side: const BorderSide(color: kPrimaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kRadiusMD),
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        // Borders
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusMD),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusMD),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusMD),
          borderSide: const BorderSide(color: kPrimaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusMD),
          borderSide: const BorderSide(color: kErrorColor, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kRadiusMD),
          borderSide: const BorderSide(color: kErrorColor, width: 2),
        ),

        // Labels & hints
        labelStyle: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade700,
          letterSpacing: 0.15,
        ),
        floatingLabelStyle: const TextStyle(
          fontSize: 14,
          color: kPrimaryColor,
          letterSpacing: 0.15,
        ),
        hintStyle: TextStyle(
          fontSize: 14,
          color: Colors.grey.shade500,
          letterSpacing: 0.25,
        ),
      ),

      // List tile theme
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusSM),
        ),
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
        space: 1,
      ),

      // Dialog theme
      dialogTheme: DialogTheme(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusLG),
        ),
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          letterSpacing: 0.15,
        ),
        contentTextStyle: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          letterSpacing: 0.25,
        ),
      ),

      // SnackBar theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF323232),
        contentTextStyle: const TextStyle(fontSize: 14, letterSpacing: 0.25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusSM),
        ),
        elevation: 6,
      ),

      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(kRadiusLG)),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      // Chip theme
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade100,
        selectedColor: kPrimaryColor.withOpacity(0.2),
        labelStyle: const TextStyle(fontSize: 13, letterSpacing: 0.25),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusSM),
        ),
      ),
    );
  }

  /// Build dark theme
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: kPrimaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kPrimaryColor,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color.fromARGB(255, 74, 61, 61),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 90, 74, 74),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        indicatorColor: kPrimaryColor.withValues(alpha: 0.3),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: kPrimaryLightColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            );
          }
          return const TextStyle(color: Colors.grey, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: kPrimaryLightColor);
          }
          return const IconThemeData(color: Colors.grey);
        }),
      ),
      cardColor: const Color(0xFF1E1E1E),
      dividerColor: Colors.grey.shade800,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF2E2E2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusSM),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kRadiusLG),
        ),
      ),
    );
  }

  /// Generate routes
  Route<dynamic>? _generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Auth routes
      case kRouteSplash:
        return _buildRoute(const SplashScreen(), settings);
      case kRouteWelcome:
        return _buildRoute(const WelcomeScreen(), settings);
      case kRouteSignIn:
        return _buildRoute(const SignInScreen(), settings);
      case kRouteSignUp:
        return _buildRoute(const SignUpScreen(), settings);

      // Main routes
      case kRouteHome:
        return _buildRoute(const HomeScreen(), settings);
      case kRouteContacts:
        return _buildRoute(const ContactScreen(), settings);
      case kRouteFavorites:
        return _buildRoute(const FavoritesScreen(), settings);
      case kRouteChat:
        return _buildRoute(const ChatScreen(), settings);
      case kRouteContactInfo:
        return _buildRoute(const ContactInfoScreen(), settings);

      // Profile routes
      case kRouteProfile:
        return _buildRoute(const ProfileScreen(), settings);
      case kRouteSettings:
        return _buildRoute(const SettingsScreen(), settings);

      // Default fallback
      default:
        return _buildRoute(const SplashScreen(), settings);
    }
  }

  /// Build material page route
  MaterialPageRoute _buildRoute(Widget page, RouteSettings settings) {
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
