// =============================================================================
// YemenChat - Settings Screen
// =============================================================================
// App settings screen for theme, notifications, etc.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/settings_controller.dart';
import '../../utils/constants.dart';

/// Settings screen
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsController = context.watch<SettingsController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        foregroundColor: Colors.white,
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Appearance section
          _buildSectionHeader('Appearance'),

          // Theme mode
          ListTile(
            leading: Icon(
              settingsController.isDarkMode
                  ? Icons.dark_mode
                  : Icons.light_mode,
              color: kPrimaryColor,
            ),
            title: const Text('Dark Mode'),
            subtitle: Text(
              settingsController.isDarkMode ? 'Enabled' : 'Disabled',
            ),
            trailing: Switch(
              value: settingsController.isDarkMode,
              onChanged: (_) => settingsController.toggleDarkMode(),
              activeColor: kPrimaryColor,
            ),
          ),

          // Theme selector
          ListTile(
            leading: const Icon(Icons.palette_outlined, color: kPrimaryColor),
            title: const Text('Theme'),
            subtitle: Text(_getThemeName(settingsController.themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeSelector(context, settingsController),
          ),

          const Divider(),

          // Notifications section
          _buildSectionHeader('Notifications'),

          SwitchListTile(
            secondary: const Icon(
              Icons.notifications_outlined,
              color: kPrimaryColor,
            ),
            title: const Text('Push Notifications'),
            subtitle: Text(
              settingsController.notificationsEnabled ? 'Enabled' : 'Disabled',
            ),
            value: settingsController.notificationsEnabled,
            onChanged: settingsController.setNotificationsEnabled,
            activeColor: kPrimaryColor,
          ),

          const Divider(),

          // Session section
          _buildSectionHeader('Session'),

          ListTile(
            leading: const Icon(Icons.timer_outlined, color: kPrimaryColor),
            title: const Text('Session Duration'),
            subtitle: Text(
              settingsController.getSessionDurationText(
                settingsController.sessionDurationMinutes,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap:
                () => _showSessionDurationSelector(context, settingsController),
          ),

          const Divider(),

          // About section
          _buildSectionHeader('About'),

          ListTile(
            leading: const Icon(Icons.info_outline, color: kPrimaryColor),
            title: const Text('App Version'),
            subtitle: const Text(kAppVersion),
          ),

          ListTile(
            leading: const Icon(
              Icons.description_outlined,
              color: kPrimaryColor,
            ),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show terms
            },
          ),

          ListTile(
            leading: const Icon(
              Icons.privacy_tip_outlined,
              color: kPrimaryColor,
            ),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Show privacy policy
            },
          ),

          const Divider(),

          // Reset settings
          ListTile(
            leading: const Icon(Icons.restore, color: kErrorColor),
            title: const Text(
              'Reset to Defaults',
              style: TextStyle(color: kErrorColor),
            ),
            onTap: () => _confirmReset(context, settingsController),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: kPrimaryColor,
        ),
      ),
    );
  }

  String _getThemeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System Default';
    }
  }

  void _showThemeSelector(BuildContext context, SettingsController controller) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Theme'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildThemeOption(
                  context,
                  controller,
                  ThemeMode.light,
                  Icons.light_mode,
                  'Light',
                ),
                _buildThemeOption(
                  context,
                  controller,
                  ThemeMode.dark,
                  Icons.dark_mode,
                  'Dark',
                ),
                _buildThemeOption(
                  context,
                  controller,
                  ThemeMode.system,
                  Icons.settings_suggest,
                  'System Default',
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    SettingsController controller,
    ThemeMode mode,
    IconData icon,
    String label,
  ) {
    final isSelected = controller.themeMode == mode;

    return ListTile(
      leading: Icon(icon, color: isSelected ? kPrimaryColor : Colors.grey),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? kPrimaryColor : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      trailing:
          isSelected ? const Icon(Icons.check, color: kPrimaryColor) : null,
      onTap: () {
        controller.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  void _showSessionDurationSelector(
    BuildContext context,
    SettingsController controller,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Session Duration'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children:
                  controller.sessionDurationOptions.map((minutes) {
                    final isSelected =
                        controller.sessionDurationMinutes == minutes;
                    return ListTile(
                      title: Text(controller.getSessionDurationText(minutes)),
                      trailing:
                          isSelected
                              ? const Icon(Icons.check, color: kPrimaryColor)
                              : null,
                      onTap: () {
                        controller.setSessionDuration(minutes);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
            ),
          ),
    );
  }

  void _confirmReset(BuildContext context, SettingsController controller) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Reset Settings'),
            content: const Text(
              'Are you sure you want to reset all settings to their default values?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  controller.resetToDefaults();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings reset to defaults')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: kErrorColor),
                child: const Text('Reset'),
              ),
            ],
          ),
    );
  }
}
