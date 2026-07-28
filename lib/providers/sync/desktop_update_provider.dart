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
      // 1. Remove build metadata (anything after +) and prefix 'v'
      final cleanRemote = remoteVersion.trim().replaceAll(RegExp(r'^v'), '').split('+').first;
      final cleanLocal = localVersion.trim().replaceAll(RegExp(r'^v'), '').split('+').first;

      // 2. Separate base version numbers from pre-release tag (after -)
      final remoteSplit = cleanRemote.split('-');
      final localSplit = cleanLocal.split('-');

      final remoteBase = remoteSplit.first.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final localBase = localSplit.first.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      // Compare base numbers (X.Y.Z)
      final maxLen = remoteBase.length > localBase.length ? remoteBase.length : localBase.length;
      for (int i = 0; i < maxLen; i++) {
        final r = i < remoteBase.length ? remoteBase[i] : 0;
        final l = i < localBase.length ? localBase[i] : 0;
        if (r > l) return true;
        if (r < l) return false;
      }

      // Base numbers are identical (e.g. 1.3.0 vs 1.3.0-beta.1 or 1.3.0-beta.1 vs 1.3.0-beta.2)
      final bool remoteHasPre = remoteSplit.length > 1;
      final bool localHasPre = localSplit.length > 1;

      // Stable release (no pre-release tag) is newer than pre-release tag
      if (!remoteHasPre && localHasPre) return true; // 1.3.0 > 1.3.0-beta.1
      if (remoteHasPre && !localHasPre) return false; // 1.3.0-beta.1 < 1.3.0

      // Both have pre-release tags (e.g. 1.3.0-beta.2 vs 1.3.0-beta.1)
      if (remoteHasPre && localHasPre) {
        final remotePreStr = remoteSplit.sublist(1).join('-');
        final localPreStr = localSplit.sublist(1).join('-');

        final remotePreNum = int.tryParse(remotePreStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final localPreNum = int.tryParse(localPreStr.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

        return remotePreNum > localPreNum;
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

    // All 5 attempts failed silently — mark as offline/error so UI can reflect it
    state = const DesktopUpdateState(
      status: DesktopUpdateStatus.error,
      errorMessage: 'Could not reach update server. Check your connection.',
      isManual: false,
    );
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
