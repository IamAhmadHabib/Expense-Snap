import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('feature Dart files use centralized color tokens', () {
    final violations = <String>[];

    for (final file in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart') ||
          file.path.endsWith('app_colors.dart')) {
        continue;
      }

      final source = file.readAsStringSync();
      if (RegExp(r'Color\(0x[0-9A-Fa-f]{8}\)').hasMatch(source) ||
          RegExp(
            r'Colors\.(?:white(?:70)?|black(?:12|26)?)\b',
          ).hasMatch(source)) {
        violations.add(file.path);
      }
    }

    expect(violations, isEmpty, reason: 'Use AppColors tokens in $violations');
  });

  test('web and mobile launch surfaces use the Kharcha warm background', () {
    final manifest = File('web/manifest.json').readAsStringSync();
    expect(manifest, contains('"background_color": "#FAF8F4"'));
    expect(manifest, contains('"theme_color": "#FAF8F4"'));

    for (final path in [
      'android/app/src/main/res/drawable/launch_background.xml',
      'android/app/src/main/res/drawable-v21/launch_background.xml',
      'android/app/src/main/res/values/styles.xml',
      'android/app/src/main/res/values-night/styles.xml',
    ]) {
      expect(
        File(path).readAsStringSync(),
        contains('@color/kharcha_background'),
        reason: path,
      );
    }

    for (final path in [
      'ios/Runner/Base.lproj/LaunchScreen.storyboard',
      'ios/Runner/Base.lproj/Main.storyboard',
    ]) {
      final storyboard = File(path).readAsStringSync();
      expect(
        storyboard,
        contains('red="0.9803921569" green="0.9725490196" blue="0.9568627451"'),
        reason: path,
      );
    }
  });
}
