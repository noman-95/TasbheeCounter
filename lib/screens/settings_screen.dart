import 'package:flutter/material.dart';

import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  final ValueChanged<bool> onThemeChanged;
  final bool isDarkMode;

  const SettingsScreen({
    super.key,
    required this.onThemeChanged,
    required this.isDarkMode,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool vibrationEnabled = false;

  static const Color primaryGreen = Color(0xFF087F5B);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final savedVibration =
        await StorageService.getVibration();

    if (!mounted) return;

    setState(() {
      vibrationEnabled = savedVibration;
    });
  }

  Future<void> _changeVibration(bool value) async {
    setState(() {
      vibrationEnabled = value;
    });

    await StorageService.saveVibration(value);
  }

  Future<void> _resetAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset All Data'),
          content: const Text(
            'This will delete all counting data, '
            'today count and complete history.\n\n'
            'Are you sure you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await StorageService.saveCount(0);

    await StorageService.saveTotal(0);

    await StorageService.resetAllCountingData();

    await StorageService.clearHistory();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'All counting data has been reset.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'General',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: SwitchListTile(
              secondary: const Icon(
                Icons.vibration_rounded,
              ),
              title: const Text('Vibration'),
              subtitle: const Text(
                'Vibrate when you tap the counter',
              ),
              value: vibrationEnabled,
              onChanged: _changeVibration,
            ),
          ),

          Card(
            child: SwitchListTile(
              secondary: const Icon(
                Icons.dark_mode_rounded,
              ),
              title: const Text('Dark Mode'),
              subtitle: const Text(
                'Use dark theme',
              ),
              value: widget.isDarkMode,
              onChanged: widget.onThemeChanged,
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            'Data',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.delete_forever_rounded,
                color: Colors.red,
              ),
              title: const Text(
                'Reset All Data',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: const Text(
                'Delete current, today, total and history',
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
              ),
              onTap: _resetAllData,
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            'About',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryGreen,
            ),
          ),

          const SizedBox(height: 10),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.info_outline_rounded,
              ),
              title: const Text(
                'Tasbih Counter',
              ),
              subtitle: const Text(
                'Version 1.0.0',
              ),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.code_rounded,
                color: primaryGreen,
              ),
              title: const Text(
                'Developed by',
              ),
              subtitle: const Text(
                'Noman Ali',
              ),
            ),
          ),

          const SizedBox(height: 25),

          Center(
            child: Text(
              'Tasbih Counter • Version 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


