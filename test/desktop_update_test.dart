import 'package:flutter_test/flutter_test.dart';
import 'package:gateletics/providers/providers.dart';

void main() {
  group('DesktopUpdateNotifier SemVer Comparison Tests', () {
    test('Remote version newer than local version returns true', () {
      expect(DesktopUpdateNotifier.isNewerVersion('v1.3.0', '1.2.16'), isTrue);
      expect(DesktopUpdateNotifier.isNewerVersion('2.0.0', '1.9.9'), isTrue);
      expect(DesktopUpdateNotifier.isNewerVersion('1.2.17', '1.2.16'), isTrue);
      expect(DesktopUpdateNotifier.isNewerVersion('1.3.0', '1.3.0-beta.1'), isTrue);
      expect(DesktopUpdateNotifier.isNewerVersion('1.3.0-beta.2', '1.3.0-beta.1'), isTrue);
    });

    test('Same remote version returns false', () {
      expect(DesktopUpdateNotifier.isNewerVersion('v1.2.16', '1.2.16'), isFalse);
      expect(DesktopUpdateNotifier.isNewerVersion('1.2.16+19', '1.2.16'), isFalse);
      expect(DesktopUpdateNotifier.isNewerVersion('1.3.0-beta.1', '1.3.0-beta.1'), isFalse);
    });

    test('Older remote version returns false', () {
      expect(DesktopUpdateNotifier.isNewerVersion('v1.2.15', '1.2.16'), isFalse);
      expect(DesktopUpdateNotifier.isNewerVersion('1.0.0', '1.2.16'), isFalse);
      expect(DesktopUpdateNotifier.isNewerVersion('1.3.0-beta.1', '1.3.0'), isFalse);
    });
  });

  group('DesktopReleaseInfo JSON Parsing Tests', () {
    test('Parses GitHub latest release JSON correctly', () {
      final json = {
        'tag_name': 'v1.3.0',
        'body': 'Added new desktop features and installer.',
        'html_url': 'https://github.com/vishnunandan555/gateletics/releases/tag/v1.3.0',
        'assets': [
          {
            'name': 'gateletics-windows-v1.3.0-setup.exe',
            'browser_download_url': 'https://example.com/gateletics-windows-v1.3.0-setup.exe',
          },
          {
            'name': 'gateletics-linux-v1.3.0.AppImage',
            'browser_download_url': 'https://example.com/gateletics-linux-v1.3.0.AppImage',
          },
          {
            'name': 'gateletics-linux-v1.3.0.deb',
            'browser_download_url': 'https://example.com/gateletics-linux-v1.3.0.deb',
          },
        ]
      };

      final info = DesktopReleaseInfo.fromJson(json);

      expect(info.latestVersion, equals('1.3.0'));
      expect(info.releaseNotes, contains('desktop features'));
      expect(info.windowsInstallerUrl, equals('https://example.com/gateletics-windows-v1.3.0-setup.exe'));
      expect(info.linuxAppImageUrl, equals('https://example.com/gateletics-linux-v1.3.0.AppImage'));
      expect(info.linuxDebUrl, equals('https://example.com/gateletics-linux-v1.3.0.deb'));
    });
  });
}
