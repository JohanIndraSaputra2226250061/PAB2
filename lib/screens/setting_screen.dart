import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return ListTile(
            title: const Text('Mode Gelap'),
            trailing: Switch(
              value: themeProvider.isDarkMode,
              onChanged: (value) => themeProvider.toggleTheme(),
            ),
          );
        },
      ),
    );
  }
}