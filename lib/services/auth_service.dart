import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/security_log_model.dart';
import '../utils/constants.dart';

/// Service class for handling authentication operations
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===========================================================================
  // GETTERS
  // ===========================================================================
  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ===========================================================================
  // SIGN UP
  // ===========================================================================
  /// Sign up a new user with email and password
  /// Also creates user profile in Firestore
  /* SIGN UP
     تستخدم _auth.createUserWithEmailAndPassword().
     إذا نجحت، تنشئ UserModel وتحفظه في مجموعة kUsersCollection في Firestore.
     تسجل إجراء الأمان (SecurityAction.login).
     تتعامل مع أخطاء FirebaseAuthException وتُعيد رمي Exception برسالة مناسبة.
   */
  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required String phone,
  }) async {
    try {
      // Create user in Firebase Auth
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Failed to create user');
      }

      // Create user model
      final user = UserModel(
        id: credential.user!.uid,
        fullName: fullName,
        username: username.toLowerCase(),
        phone: phone,
        email: email.toLowerCase(),
        createdAt: DateTime.now(),
      );

      // Save user profile to Firestore
      await _firestore
          .collection(kUsersCollection)
          .doc(user.id)
          .set(user.toMap());

      // Log the signup action
      await _logSecurityAction(user.id, SecurityAction.login);

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ===========================================================================
  // SIGN IN
  // ===========================================================================
  /// Sign in with email and password
  /// Also retrieves user profile from Firestore
  /// Logs the login action
  /*
     تستخدم _auth.signInWithEmailAndPassword().
     إذا نجحت، تجلب ملف الملف الشخصي من Firestore.
     تسجل إجراء الأمان (SecurityAction.login).
     تتعامل مع أخطاء FirebaseAuthException وتُعيد رمي Exception برسالة مناسبة.
   */
  Future<UserModel?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw Exception('Failed to sign in');
      }

      // Get user profile from Firestore
      final user = await getUserProfile(credential.user!.uid);

      // Log the login action
      await _logSecurityAction(credential.user!.uid, SecurityAction.login);

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Sign in with username (finds email first, then signs in)
  /// Also retrieves user profile from Firestore
  /// Logs the login action
  /*
    تبحث أولاً عن المستخدم في Firestore باستخدام اسم المستخدم للحصول على بريده الإلكتروني.
    إذا لم يتم العثور على المستخدم، ترفع خطأ.
    ثم تستدعي signInWithEmail().
    إذا نجحت، تجلب ملف الملف الشخصي من Firestore.
    تسجل إجراء الأمان (SecurityAction.login).
    تتعامل مع أخطاء FirebaseAuthException وتُعيد رمي Exception برسالة مناسبة.
   */
  Future<UserModel?> signInWithUsername({
    required String username,
    required String password,
  }) async {
    try {
      // Find user by username
      final querySnapshot =
          await _firestore
              .collection(kUsersCollection)
              .where('username', isEqualTo: username.toLowerCase())
              .limit(1)
              .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('User not found');
      }

      final email = querySnapshot.docs.first.data()['email'] as String;

      // Sign in with email
      return signInWithEmail(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ===========================================================================
  // SIGN OUT
  // ===========================================================================-
  /// Sign out the current user
  /*
     تستخدم _auth.signOut().
     إذا نجحت، تسجل إجراء الأمان (SecurityAction.logout).
   */
  Future<void> signOut() async {
    final userId = currentUserId;
    if (userId != null) {
      await _logSecurityAction(userId, SecurityAction.logout);
    }
    await _auth.signOut();
  }

  // ===========================================================================
  // DUPLICATE CHECKING
  // ===========================================================================
  /// Check if email already exists
  /*
     تستخدم _firestore.collection(kUsersCollection).
     where('email', isEqualTo: email.toLowerCase()).
     limit(1).
     get().
     للتحقق من تكرار البريد الإلكتروني
     إذا كانت النتيجة ليست فارغة، ترجع true.
   */
  Future<bool> isEmailTaken(String email) async {
    final querySnapshot =
        await _firestore
            .collection(kUsersCollection)
            .where('email', isEqualTo: email.toLowerCase())
            .limit(1)
            .get();
    return querySnapshot.docs.isNotEmpty;
  }

  /// Check if username already exists
  /*
     تستخدم _firestore.collection(kUsersCollection).
     where('username', isEqualTo: username.toLowerCase()).
     limit(1).
     get().
     للتحقق من تكرار اسم المستخدم
       إذا كانت النتيجة ليست فارغة، ترجع true.
   */
  Future<bool> isUsernameTaken(String username) async {
    final querySnapshot =
        await _firestore
            .collection(kUsersCollection)
            .where('username', isEqualTo: username.toLowerCase())
            .limit(1)
            .get();
    return querySnapshot.docs.isNotEmpty;
  }

  // ===========================================================================
  // PASSWORD MANAGEMENT
  // ===========================================================================
  /// Change password for current user
  /*
     تستخدم _auth.currentUser.
     إذا كان المستخدم غير مسجل في النظام، ترفع خطأ.
     تستخدم EmailAuthProvider.credential().
     تتطلب إعادة المصادقة (re-authentication) أولاً باستخدام كلمة المرور الحالية.
     ثم تستخدم user.updatePassword(newPassword).
     إذا نجحت، تحدث كلمة المرور.
     تسجل إجراء الأمان (SecurityAction.passwordChange). 
   */
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user logged in');
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      // Log the action
      await _logSecurityAction(user.uid, SecurityAction.passwordChange);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  /// Send password reset email
  ///
  /*
     تستخدم _auth.sendPasswordResetEmail(). للإرسال بريد إعادة تعيين كلمة المرور
   */
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ===========================================================================
  // USER PROFILE
  // ===========================================================================
  /// Get user profile from Firestore
  /*
    لجلب بيانات الملف الشخصي لمستخدم معين من Firestore.
     تستخدم _firestore.collection(kUsersCollection).
     doc(userId).
     get().
     إذا كانت النتيجة ليست موجودة، ترجع null.
     تستخدم UserModel.fromFirestore().
   */
  Future<UserModel?> getUserProfile(String userId) async {
    final doc = await _firestore.collection(kUsersCollection).doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Get current user profile
  /*
     لتحديث بيانات الملف الشخصي.
     إذا كان currentUserId فارغاً، ترجع null.
     تستخدم getUserProfile().
   */
  Future<UserModel?> getCurrentUserProfile() async {
    if (currentUserId == null) return null;
    return getUserProfile(currentUserId!);
  }

  /// Update user profile
  /*
     لتحديث بيانات الملف الشخصي.
     تستخدم _firestore.collection(kUsersCollection).
     doc(user.id).
     update(user.toMap()).
   */
  Future<void> updateUserProfile(UserModel user) async {
    await _firestore
        .collection(kUsersCollection)
        .doc(user.id)
        .update(user.toMap());

    await _logSecurityAction(user.id, SecurityAction.profileUpdate);
  }

  /// Update FCM token for push notifications
  /*
     لتحديث رمز FCM (Firebase Cloud Messaging).
     إذا كان currentUserId فارغاً، ترجع.
     تستخدم _firestore.collection(kUsersCollection).
     doc(currentUserId).
     update({
       'fcmToken': token,
     }).
   */
  Future<void> updateFcmToken(String token) async {
    if (currentUserId == null) return;
    await _firestore.collection(kUsersCollection).doc(currentUserId).update({
      'fcmToken': token,
    });
  }

  // ===========================================================================
  // ACCOUNT MANAGEMENT
  // ===========================================================================
  /// Delete user account
  /*
     لحذف حساب المستخدم.
     تتطلب إعادة المصادقة.
     تحذف بيانات المستخدم من Firestore.
     تحذف حساب المستخدم من Firebase Auth.
     تستخدم _auth.currentUser.
     إذا كان المستخدم غير مسجل في النظام، ترفع خطأ.
     تستخدم EmailAuthProvider.credential().
     reauthenticateWithCredential().
     إذا نجحت، تستخدم _firestore.collection(kUsersCollection).
     doc(user.uid).
     delete().
     تستخدم user.delete().
   */
  Future<void> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user logged in');
      }

      // Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Log the action before deletion
      await _logSecurityAction(user.uid, SecurityAction.accountDelete);

      // Delete user data from Firestore
      await _firestore.collection(kUsersCollection).doc(user.uid).delete();

      // Delete Firebase Auth account
      await user.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ===========================================================================
  // SECURITY LOGGING
  // ===========================================================================
  /// Log a security action
  /*
     لتسجيل إجراء الأمان.
     تستخدم SecurityLogModel.
     add().
   */
  Future<void> _logSecurityAction(String userId, SecurityAction action) async {
    final log = SecurityLogModel(
      id: '',
      userId: userId,
      action: action,
      timestamp: DateTime.now(),
      deviceInfo: 'Flutter App', // In production, get actual device info
    );

    await _firestore.collection(kSecurityLogsCollection).add(log.toMap());
  }

  /// Get security logs for current user
  /*
     لجلب سجلات الأمان لمستخدم معين.
      إذا كان currentUserId فارغاً، ترجع فارغة.
     تستخدم _firestore.collection(kSecurityLogsCollection).
     where('userId', isEqualTo: currentUserId).
     orderBy('timestamp', descending: true).
     limit(50).
     get().
     تستخدم SecurityLogModel.fromFirestore().
   */
  Future<List<SecurityLogModel>> getSecurityLogs() async {
    if (currentUserId == null) return [];

    final querySnapshot =
        await _firestore
            .collection(kSecurityLogsCollection)
            .where('userId', isEqualTo: currentUserId)
            .orderBy('timestamp', descending: true)
            .limit(50)
            .get();

    return querySnapshot.docs
        .map((doc) => SecurityLogModel.fromFirestore(doc))
        .toList();
  }

  // ===========================================================================
  // ERROR HANDLING
  // ===========================================================================
  /// Handle Firebase Auth errors and return user-friendly messages
  /*
     لمعالجة أخطاء Firebase Auth وعرض الرسائل المستخدمية. 
     تستخدم switch.
     تستخدم FirebaseAuthException.code.
     تستخدم FirebaseAuthException.message.
   */
  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password is too weak';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later';
      case 'operation-not-allowed':
        return 'This operation is not allowed';
      default:
        return e.message ?? 'An error occurred. Please try again';
    }
  }
}
