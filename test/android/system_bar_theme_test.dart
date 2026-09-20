import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android launch themes stay light in day and night modes', () {
    for (final path in <String>[
      'android/app/src/main/res/values/styles.xml',
      'android/app/src/main/res/values-night/styles.xml',
    ]) {
      final contents = File(path).readAsStringSync();

      expect(contents, isNot(contains('Theme.Black')));
      expect(contents, contains('Theme.Light.NoTitleBar'));
      expect(contents, contains('#EAF1FF'));
      expect(contents, contains('android:windowLightStatusBar'));
      expect(contents, contains('android:windowLightNavigationBar'));
      expect(contents, contains('true'));
    }
  });
}
