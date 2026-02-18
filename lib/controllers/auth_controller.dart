import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

/// Controller for managing authentication state
class AuthController extends ChangeNotifier {
  // Services
  final AuthService _authService =
      AuthService(); // نسخة من AuthService للتعامل مع عمليات المصادقة الفعلية (مثل الاتصال بFirebase).
  final NotificationService _notificationService =
      NotificationService(); // نسخة من NotificationService للتعامل مع الإشعارات.

  // State
  UserModel? _currentUser; // كائن UserModel لتخزين بيانات المستخدم الحالي.
  bool _isLoading =
      false; // متغير منطقي لتتبع حالة التحميل (true إذا كانت عملية المصادقة قيد التنفيذ، false إذا انتهت).
  String? _errorMessage; // متغير لتخزين رسالة الخطأ (إن وجدت).
  bool _isInitialized = false; // متغير منطقي لتتبع حالة تهيئة المصادقة.

  // ===========================================================================
  // GETTERS
  // ===========================================================================
  /// Current logged in user
  /// جلب المستخدم الحالي
  UserModel? get currentUser => _currentUser;

  /// Check if user is logged in
  /// التحقق إذا كان المستخدم مسجل دخوله
  bool get isLoggedIn => _currentUser != null;

  /// Check if authentication is loading
  /// التحقق إذا كانت عملية المصادقة قيد التحميل
  bool get isLoading => _isLoading;

  /// Get error message (if any)
  /// جلب رسالة الخطأ (إن وجدت)
  String? get errorMessage => _errorMessage;

  /// Check if auth state has been initialized
  /// التحقق إذا كانت حالة المصادقة قد تم تهيئتها
  bool get isInitialized => _isInitialized;

  /// Get current user ID
  /// جلب معرّف المستخدم الحالي
  String? get currentUserId => _currentUser?.id;

  // ===========================================================================
  // INITIALIZATION
  // ===========================================================================
  /* Initialize auth controller and check login state
    1-تقوم بتشغيل Loading
    2-تتحقق إذا كان هناك مستخدم مسجل دخوله مسبقاً 
    3-إذا كان يوجد، تحصل على بيانات الملف الشخصي للمستخدم
    4-تحصل على رمز FCM (Firebase Cloud Messaging)
     الخاص بالجهاز وتحدثه في ملف المستخدم عبر _authService.updateFcmToken(token).
     هذا مهم لإرسال الإشعارات إلى الجهاز الصحيح.
    5-تقوم بإيقاف Loading
  */
  Future<void> initialize() async {
    _setLoading(true);

    try {
      // Check if user is already logged in
      /*تتحقق إذا كان هناك مستخدم مسجل دخوله مسبقاً 
      إذا كان يوجد، تحصل على بيانات الملف الشخصي للمستخدم

      تحصل على رمز FCM (Firebase Cloud Messaging)
       الخاص بالجهاز وتحدثه في ملف المستخدم عبر _authService.updateFcmToken(token).
       هذا مهم لإرسال الإشعارات إلى الجهاز الصحيح.
      */
      if (_authService.isLoggedIn) {
        _currentUser = await _authService.getCurrentUserProfile();

        // Update FCM token
        if (_currentUser != null) {
          final token = await _notificationService.getToken();
          if (token != null) {
            await _authService.updateFcmToken(token);
          }
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to initialize: $e';
    } finally {
      _isInitialized = true;
      _setLoading(false);
    }
  }






  // ===========================================================================
  // SIGN UP
  // ===========================================================================
  /* Sign up a new user
    1-تقوم بتشغيل Loading
    2-تتحقق أولاً إذا كان البريد الإلكتروني أو اسم المستخدم مسجلين مسبقاً.
    3-تستدعي _authService.signUp() لإنشاء المستخدم في Firebase.
    4-إذا نجحت العملية، تحصل على رمز FCM وتحدثه.
    5-تُرجع true إذا نجحت العملية، false إذا فشلت.
    6-تقوم بإيقاف Loading
  */
  Future<bool> signUp({
    required String fullName,
    required String username,
    required String phone,
    required String email,
    required String password,
  }) async {
    _clearError();
    _setLoading(true);

    try {
      // Check for duplicate email
      if (await _authService.isEmailTaken(email)) {
        throw Exception('This email is already registered');
      }

      // Check for duplicate username
      if (await _authService.isUsernameTaken(username)) {
        throw Exception('This username is already taken');
      }

      // Create account
      _currentUser = await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        username: username,
        phone: phone,
      );

      // Update FCM token
      final token = await _notificationService.getToken();
      if (token != null && _currentUser != null) {
        await _authService.updateFcmToken(token);
      }

      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // ===========================================================================
  // SIGN IN
  // ===========================================================================
  /* Sign in with email or username
    1-تقوم بتشغيل Loading
    2-تتحقق إذا كان المدخل بريداً إلكترونياً (يحتوي على @) أو اسم مستخدم.
    3-تستدعي الدالة المناسبة من _authService (signInWithEmail أو signInWithUsername).
    4-إذا نجحت العملية، تحصل على رمز FCM وتحدثه.
    5-تُرجع true إذا نجحت العملية، false إذا فشلت.
    6-تقوم بإيقاف Loading
  */
  Future<bool> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    _clearError();
    _setLoading(true);

    try {
      // Check if input is email or username
      if (emailOrUsername.contains('@')) {
        // Sign in with email
        _currentUser = await _authService.signInWithEmail(
          email: emailOrUsername,
          password: password,
        );
      } else {
        // Sign in with username
        _currentUser = await _authService.signInWithUsername(
          username: emailOrUsername,
          password: password,
        );
      } 

      // Update FCM token
      final token = await _notificationService.getToken();
      if (token != null && _currentUser != null) {
        await _authService.updateFcmToken(token);
      }

      _setLoading(false);
      return true;
    } 
    catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // ===========================================================================
  // SIGN OUT
  // ===========================================================================
  /* Sign out current user
    1-تقوم بتشغيل Loading
    2-تستدعي _authService.signOut() لتسجيل الخروج من Firebase.
    3-تُعين _currentUser إلى null.
    4-تقوم بإيقاف Loading
  */
  Future<void> signOut() async {
    _setLoading(true);

    try {
      await _authService.signOut();
      _currentUser = null;
    } catch (e) {
      _errorMessage = 'Failed to sign out: $e';
    } finally {
      _setLoading(false);
    }
  }

  // ===========================================================================
  // PASSWORD MANAGEMENT
  // ===========================================================================
  /// Change password
  /* Change password
    1-تقوم بتشغيل Loading
    2-تستدعي _authService.changePassword() لتغيير كلمة المرور.
    3-تقوم بإيقاف Loading
  */
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _clearError();
    _setLoading(true);

    try {
      await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  /* Send password reset email
    1-تقوم بتشغيل Loading
    2-تستدعي _authService.sendPasswordResetEmail() لإرسال رابط إعادة تعيين كلمة المرور.
    3-تقوم بإيقاف Loading
  */
  Future<bool> sendPasswordReset(String email) async {
    _clearError();
    _setLoading(true);

    try {
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to send reset email: $e';
      _setLoading(false);
      return false;
    }
  }

  // ===========================================================================
  // PROFILE UPDATE
  // ===========================================================================
  /* Update user profile
    1-تقوم بتشغيل Loading
    2-تستدعي _authService.updateUserProfile() لتحديث بيانات المستخدم.
    3-تحدث _currentUser بالبيانات الجديدة.
    4-تقوم بإيقاف Loading
  */
  Future<bool> updateProfile(UserModel updatedUser) async {
    _clearError();
    _setLoading(true);

    try {
      await _authService.updateUserProfile(updatedUser);
      _currentUser = updatedUser;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      _setLoading(false);
      return false;
    }
  }

  /* Update profile photo URL
    1-تقوم بتشغيل Loading
    2-تنشئ نسخة جديدة من UserModel مع رابط الصورة الجديد.
    3-تستدعي updateProfile() لتحديث البيانات مع الصورة الجديدة  .
    4-تقوم بإيقاف Loading 
  */
  Future<bool> updateProfilePhoto(String photoUrl) async {
    if (_currentUser == null) return false;

    final updatedUser = _currentUser!.copyWith(photoUrl: photoUrl);
    return updateProfile(updatedUser);
  }

  // ===========================================================================
  // ACCOUNT DELETION
  // ===========================================================================
  /* Delete user account
    1-تقوم بتشغيل Loading
    2-تستدعي _authService.deleteAccount() لحذف حساب المستخدم.
    3-تُعين _currentUser إلى null.
    4-تقوم بإيقاف Loading
  */
  Future<bool> deleteAccount(String password) async {
    _clearError();
    _setLoading(true);

    try {
      await _authService.deleteAccount(password);
      _currentUser = null;
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      return false;
    }
  }

  // ===========================================================================
  // HELPER METHODS
  // ===========================================================================
  /* Set loading state
    1 -     تُحدِّث _isLoading.
    2 - تُستدعي notifyListeners(): هذه الدالة من ChangeNotifier 
    تُخطر جميع الويدجت التي تستمع إلى هذا الـ Controller
    بأن الحالة قد تغيرت، مما يؤدي إلى إعادة بنائها.
     
  */
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /* Clear error message
    1- لمسح رسالة الخطأ.
  */
  void _clearError() {
    _errorMessage = null;
  }

  /* Clear error manually
    1: نسخة عامة من _clearError() ولكنها تستدعي notifyListeners() أيضاً.
  */
  void clearError() {
    _clearError();
    notifyListeners();
  }
}
