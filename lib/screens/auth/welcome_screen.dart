// =============================================================================
// YemenChat - Welcome Screen
// =============================================================================
// Welcome screen with sign in and sign up options.
// =============================================================================

import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../widgets/custom_button.dart';

/// Welcome screen displayed to unauthenticated users
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kPrimaryColor, kPrimaryDarkColor],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),

                // Logo and app name
                _buildHeader(),

                const Spacer(flex: 3),

                // Illustration or features
                _buildFeatures(),

                const Spacer(flex: 2),

                // Action buttons
                _buildButtons(context),

                const SizedBox(height: 32),

                // Terms text
                _buildTermsText(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build header with logo and app name
  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.chat_bubble_rounded,
            size: 50,
            color: kPrimaryColor,
          ),
        ),

        const SizedBox(height: 24),

        // App name
        const Text(
          kAppName,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),

        const SizedBox(height: 8),

        // Tagline
        Text(
          'Simple. Secure. Fast.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  /// Build features list
  Widget _buildFeatures() {
    return Column(
      children: [
        _buildFeatureItem(Icons.lock_outline, 'End-to-end encryption'),
        const SizedBox(height: 16),
        _buildFeatureItem(Icons.speed_outlined, 'Fast & reliable messaging'),
        const SizedBox(height: 16),
        _buildFeatureItem(Icons.group_outlined, 'Connect with everyone'),
      ],
    );
  }

  /// Build single feature item
  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 24),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  /// Build action buttons
  Widget _buildButtons(BuildContext context) {
    return Column(
      children: [
        // Sign Up button (primary)
        CustomButton(
          text: 'Create Account',
          backgroundColor: Colors.white,
          textColor: kPrimaryColor,
          icon: Icons.person_add_outlined,
          onPressed: () {
            Navigator.pushNamed(context, kRouteSignUp);
          },
        ),

        const SizedBox(height: 16),

        // Sign In button (outlined)
        CustomButton(
          text: 'Sign In',
          isOutlined: true,
          backgroundColor: Colors.white,
          icon: Icons.login,
          onPressed: () {
            Navigator.pushNamed(context, kRouteSignIn);
          },
        ),
      ],
    );
  }

  /// Build terms text
  Widget _buildTermsText() {
    return Text(
      'By continuing, you agree to our\nTerms of Service and Privacy Policy',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: Colors.white.withValues(alpha: 0.6),
      ),
    );
  }
}
