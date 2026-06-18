import 'package:flutter/material.dart';

import 'features/timetable/presentation/timetable_page.dart';

class KiroTimeApp extends StatelessWidget {
  const KiroTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KiroTime',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF157A6E)),
        useMaterial3: true,
      ),
      home: const TimetablePage(),
    );
  }
}
