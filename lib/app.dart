import 'package:flutter/material.dart';

import 'features/timetable/presentation/timetable_page.dart';
import 'ui/kiro_theme.dart';

class KiroTimeApp extends StatelessWidget {
  const KiroTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KiroTime',
      debugShowCheckedModeBanner: false,
      theme: buildKiroTheme(),
      home: const TimetablePage(),
    );
  }
}
