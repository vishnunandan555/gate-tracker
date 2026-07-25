import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import 'package_info_provider.dart';

class DesktopReleaseInfo {
  final String latestVersion;
  final String releaseNotes;
  final String htmlUrl;
  final String? windowsInstallerUrl;
  final String? windowsZipUrl;
  final String? linuxAppImageUrl;
  final String? linuxDebUrl;
  final String? linuxTarballUrl;

  const DesktopReleaseInfo({
    required this.latestVersion,
    required this.releaseNotes,
    required this.htmlUrl,
    this.windowsInstallerUrl,
    this.windowsZipUrl,
    this.linuxAppImageUrl,
    this.linuxDebUrl,
    this.linuxTarballUrl,
  });

  factory DesktopReleaseInfo.fromJson(Map<String, dynamic> json) {
    final tagName = (json['tag_name'] as String? ?? '').replaceFirst(RegExp(r'^v'), '');
    final notes = json['body'] as String? ?? '';
    final url = json['html_url'] as String? ?? 'https://github.com/vishnunandan555/gateletics/releases';

    String? winInstaller;
    String? winZip;
    String? linAppImage;
    String? linDeb;
    String? linTar;

    final assets = json['assets'] as List<dynamic>? ?? [];
    for (final asset in assets) {
      if (asset is Map<String, dynamic>) {
        final name = asset['name'] as String? ?? '';
        final downloadUrl = asset['browser_download_url'] as String? ?? '';
        if (name.endsWith('-setup.exe')) {
          winInstaller = downloadUrl;
        } else if (name.endsWith('.zip') && name.contains('windows')) {
          winZip = downloadUrl;
        } else if (name.endsWith('.AppImage')) {
          linAppImage = downloadUrl;
        } else if (name.endsWith('.deb')) {
          linDeb = downloadUrl;
        } else if (name.endsWith('.tar.gz') && name.contains('linux')) {
          linTar = downloadUrl;
        }
      }
    }

    return DesktopReleaseInfo(
      latestVersion: tagName,
      releaseNotes: notes,
      htmlUrl: url,
      windowsInstallerUrl: winInstaller,
      windowsZipUrl: winZip,
      linuxAppImageUrl: linAppImage,
      linuxDebUrl: linDeb,
      linuxTarballUrl: linTar,
    );
  }
}

enum DesktopUpdateStatus {
  idle,
  checking,
  upToDate,
  updateAvailable,
  error,
}

class DesktopUpdateState {
  final DesktopUpdateStatus status;
  final DesktopReleaseInfo? releaseInfo;
  final String? errorMessage;
  final bool isManual;

  const DesktopUpdateState({
    this.status = DesktopUpdateStatus.idle,
    this.releaseInfo,
    this.errorMessage,
    this.isManual = false,
  });

  DesktopUpdateState copyWith({
    DesktopUpdateStatus? status,
    DesktopReleaseInfo? releaseInfo,
    String? errorMessage,
    bool? isManual,
  }) {
    return DesktopUpdateState(
      status: status ?? this.status,
      releaseInfo: releaseInfo ?? this.releaseInfo,
      errorMessage: errorMessage,
      isManual: isManual ?? this.isManual,
    );
  }
}

class DesktopUpdateNotifier extends Notifier<DesktopUpdateState> {
  @override
  DesktopUpdateState build() {
    return const DesktopUpdateState();
  }

  PackageInfo get packageInfo => ref.read(packageInfoProvider);

  bool get isDesktopPlatform {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  /// Semver comparator: returns true if [remoteVersion] is strictly newer than [localVersion]
  static bool isNewerVersion(String remoteVersion, String localVersion) {
    try {
      final cleanRemoteStr = remoteVersion.split('+').first.replaceAll(RegExp(r'[^0-9.]'), '');
      final cleanLocalStr = localVersion.split('+').first.replaceAll(RegExp(r'[^0-9.]'), '');

      final remoteParts = cleanRemoteStr.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final localParts = cleanLocalStr.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      final maxLength = remoteParts.length > localParts.length ? remoteParts.length : localParts.length;
      for (int i = 0; i < maxLength; i++) {
        final r = i < remoteParts.length ? remoteParts[i] : 0;
        final l = i < localParts.length ? localParts[i] : 0;
        if (r > l) return true;
        if (r < l) return false;
      }
    } catch (_) {}
    return false;
  }

  /// Triggers on desktop launch: performs up to 5 silent retries with backoff delays
  Future<void> checkOnLaunchSilently() async {
    if (!isDesktopPlatform) return;
    if (state.status == DesktopUpdateStatus.checking) return;

    final retryDelays = const [
      Duration(seconds: 5),
      Duration(seconds: 15),
      Duration(seconds: 30),
      Duration(seconds: 60),
      Duration(seconds: 120),
    ];

    for (int attempt = 1; attempt <= 5; attempt++) {
      try {
        final response = await http.get(
          Uri.parse('https://api.github.com/repos/vishnunandan555/gateletics/releases/latest'),
          headers: {'Accept': 'application/vnd.github.v3+json'},
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final info = DesktopReleaseInfo.fromJson(data);

          if (isNewerVersion(info.latestVersion, packageInfo.version)) {
            state = DesktopUpdateState(
              status: DesktopUpdateStatus.updateAvailable,
              releaseInfo: info,
              isManual: false,
            );
          } else {
            state = DesktopUpdateState(
              status: DesktopUpdateStatus.upToDate,
              releaseInfo: info,
              isManual: false,
            );
          }
          return; // Success!
        }
      } catch (e) {
        debugPrint('Silent update check attempt $attempt failed: $e');
      }

      // If attempt failed and more retries remain, wait backoff delay before trying again
      if (attempt < 5) {
        await Future.delayed(retryDelays[attempt - 1]);
      }
    }

    // All 5 attempts failed silently -> quietly cancel without displaying errors
    state = const DesktopUpdateState(status: DesktopUpdateStatus.idle);
  }

  /// Triggered manually by user clicking "Check for Updates" in Settings / About page
  Future<void> checkManually() async {
    if (!isDesktopPlatform) return;

    state = const DesktopUpdateState(
      status: DesktopUpdateStatus.checking,
      isManual: true,
    );

    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/vishnunandan555/gateletics/releases/latest'),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final info = DesktopReleaseInfo.fromJson(data);

        if (isNewerVersion(info.latestVersion, packageInfo.version)) {
          state = DesktopUpdateState(
            status: DesktopUpdateStatus.updateAvailable,
            releaseInfo: info,
            isManual: true,
          );
        } else {
          state = DesktopUpdateState(
            status: DesktopUpdateStatus.upToDate,
            releaseInfo: info,
            isManual: true,
          );
        }
      } else {
        state = DesktopUpdateState(
          status: DesktopUpdateStatus.error,
          errorMessage: 'Server returned HTTP ${response.statusCode}',
          isManual: true,
        );
      }
    } catch (e) {
      state = const DesktopUpdateState(
        status: DesktopUpdateStatus.error,
        errorMessage: 'Could not connect to update server.',
        isManual: true,
      );
    }
  }
}

final desktopUpdateProvider = NotifierProvider<DesktopUpdateNotifier, DesktopUpdateState>(DesktopUpdateNotifier.new);
