import 'package:flutter/material.dart';

enum AppThemeMode { system, light, dark }

class SettingsStore {
  static final detailedGraph = ValueNotifier<bool>(false);
  static final themeMode = ValueNotifier<AppThemeMode>(AppThemeMode.system);
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
          
        children: [
          const SizedBox(height: 50),
          // Detailed Graph Switch
          ValueListenableBuilder<bool>(
            valueListenable: SettingsStore.detailedGraph,
            builder: (context, value, _) => SwitchListTile(
              title: const Text('Detailed Graph'),
              subtitle: const Text('Adds grids and additional information to graphs'),
              value: value,
              onChanged: (val) => SettingsStore.detailedGraph.value = val,
            ),
          ),
          // Theme Dropdown
          ValueListenableBuilder<AppThemeMode>(
            valueListenable: SettingsStore.themeMode,
            builder: (context, value, _) => ListTile(
              title: const Text('Theme'),
              subtitle: const Text('Choose system default, dark or light'),
              trailing: DropdownButton<AppThemeMode>(
                value: value,
                items: const [
                  DropdownMenuItem(
                    value: AppThemeMode.system,
                    child: Text('System Default'),
                  ),
                  DropdownMenuItem(
                    value: AppThemeMode.light,
                    child: Text('Light'),
                  ),
                  DropdownMenuItem(
                    value: AppThemeMode.dark,
                    child: Text('Dark'),
                  ),
                ],
                onChanged: (mode) {
                  if (mode != null) SettingsStore.themeMode.value = mode;
                },
              ),
            ),
          ),
          const SizedBox(height: 50),
          Text("Made by Viswasurya Palkumar",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}