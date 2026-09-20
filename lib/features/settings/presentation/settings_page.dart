import 'package:flutter/material.dart';

import '../../../ui/glass.dart';
import 'settings_center_dialog.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KiroPalette.canvasGradient.first,
      appBar: AppBar(
        title: const Text('设置'),
        backgroundColor: Colors.white.withValues(alpha: 0.76),
        surfaceTintColor: Colors.transparent,
      ),
      body: const SafeArea(
        top: false,
        child: SettingsCenterDialog(fullScreen: true),
      ),
    );
  }
}
