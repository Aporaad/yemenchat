import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../utils/helpers.dart';
import '../widgets/input_field.dart';
import '../widgets/custom_button.dart';

/// Sign in screen for existing users
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  // Form key for validation
  final _formKey =
      GlobalKey<FormState>(); // مفتاح فريد للـ Form` للتحقق من صحة المدخلات.

  // Text controllers
  final _emailOrUsernameController =
      TextEditingController(); // يحتفظ بقيمة المدخلات في حقل البريد الإلكتروني أو اسم المستخدم.
  final _passwordController =
      TextEditingController(); // يحتفظ بقيمة المدخلات في حقل كلمة المرور.

  // Remember me checkbox
  bool _rememberMe = false; // يحتفظ بقيمة المدخلات في حقل تذكرني.

  @override
  void dispose() {
    // تحرير متحكمات النصوص لمنع تسرب الذاكرة.
    _emailOrUsernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handle sign in
  Future<void> _handleSignIn() async {
    // Validate form
    if (!_formKey.currentState!.validate()) return; // يتحقق من صحة المدخلات اذا كانت غير صحيحة يرجع false  . 

    final authController =
        context.read<AuthController>(); // الحصول على AuthController.

    // Attempt sign in
    final success = await authController.signIn(
      emailOrUsername:
          _emailOrUsernameController.text.trim(), // يتحقق من صحة المدخلات. trim: إزالة المسافات من بداية ونهاية النص
      password: _passwordController.text, // يتحقق من صحة المدخلات.
    );

    if (!mounted) return; // يتحقق من صحة المدخلات.

    if (success) {
      // Navigate to home
      Helpers.navigateClearAll(
        context,
        kRouteHome,
      ); // ينتقل إلى الشاشة الرئيسية.
    } else {
      // Show error
      Helpers.showErrorSnackBar(
        context,
        authController.errorMessage ??
            'Sign in failed', // يتحقق من صحة المدخلات.
      );
    }
  }

  /// Handle forgot password
  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (context) => _ForgotPasswordDialog(),
    ); // يظهر نافذة حذف كلمة المرور.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: kDefaultPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 32),

                // Header
                const Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to continue',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),

                const SizedBox(height: 48),

                // Email/Username field
                InputField(
                  controller: _emailOrUsernameController,
                  label: 'Email or Username',
                  hint: 'Enter your email or username',
                  prefixIcon: Icons.person_outline,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator:
                      (value) => Validators.validateRequired(
                        value,
                        'Email or Username',
                      ),
                ),

                const SizedBox(height: 20),

                // Password field
                InputField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: 'Enter your password',
                  prefixIcon: Icons.lock_outline,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  validator: Validators.validatePassword,
                  onSubmitted: (_) => _handleSignIn(),
                ),

                const SizedBox(height: 16),

                // Remember me & Forgot password row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Remember me
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                            activeColor: kPrimaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Remember me',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),

                    // Forgot password
                    GestureDetector(
                      onTap: _handleForgotPassword,
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Sign In button
                Consumer<AuthController>(
                  builder: (context, auth, child) {
                    return CustomButton(
                      text: 'Sign In',
                      isLoading: auth.isLoading,
                      onPressed: _handleSignIn,
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(context, kRouteSignUp);
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          color: kPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



/// Forgot password dialog
class _ForgotPasswordDialog extends StatefulWidget {
  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !Helpers.isValidEmail(email)) {
      Helpers.showErrorSnackBar(context, 'Please enter a valid email');
      return;
    }

    setState(() => _isLoading = true);

    final authController = context.read<AuthController>();
    final success = await authController.sendPasswordReset(email);

    setState(() {
      _isLoading = false;
      if (success) _emailSent = true;
    });

    if (!success && mounted) {
      Helpers.showErrorSnackBar(
        context,
        authController.errorMessage ?? 'Failed to send reset email',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_emailSent ? 'Email Sent!' : 'Reset Password'),
      content:
          _emailSent
              ? const Text(
                'Check your email for instructions to reset your password.',
              )
              : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter your email address and we\'ll send you a link to reset your password.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_emailSent ? 'Close' : 'Cancel'),
        ),
        if (!_emailSent)
          ElevatedButton(
            onPressed: _isLoading ? null : _sendResetEmail,
            style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
            child:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Send'),
          ),
      ],
    );
  }
}
