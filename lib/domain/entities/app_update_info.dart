// lib/domain/entities/app_update_info.dart
// Entity representing app update metadata from Firebase Realtime Database

class AppUpdateInfo {
  final String appName;
  final String packageName;
  final String platform;
  final String latestVersion;
  final String minimumVersion;
  final bool updateRequired;
  final String updateTitle;
  final String updateMessage;
  final String updateUrl;

  const AppUpdateInfo({
    required this.appName,
    required this.packageName,
    required this.platform,
    required this.latestVersion,
    required this.minimumVersion,
    required this.updateRequired,
    required this.updateTitle,
    required this.updateMessage,
    required this.updateUrl,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    return AppUpdateInfo(
      appName: json['appName'] as String? ?? 'SpyEar',
      packageName: json['packageName'] as String? ?? 'com.spyear.app',
      platform: json['platform'] as String? ?? 'android',
      latestVersion: json['latestVersion'] as String? ?? '1.0.0',
      minimumVersion: json['minimumVersion'] as String? ?? '1.0.0',
      updateRequired: json['updateRequired'] as bool? ?? false,
      updateTitle: json['updateTitle'] as String? ?? 'New Update Available',
      updateMessage: json['updateMessage'] as String? ?? 'Please update SpyEar to the latest version.',
      updateUrl: json['updateUrl'] as String? ?? 'https://play.google.com/store/apps/details?id=com.spyear.app',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'packageName': packageName,
      'platform': platform,
      'latestVersion': latestVersion,
      'minimumVersion': minimumVersion,
      'updateRequired': updateRequired,
      'updateTitle': updateTitle,
      'updateMessage': updateMessage,
      'updateUrl': updateUrl,
    };
  }

  /// Compare two semantic version strings (e.g. "1.2.1" vs "1.2.0")
  static int compareVersions(String v1, String v2) {
    // Strip build numbers if present (e.g., "1.2.1+5" -> "1.2.1")
    final v1Clean = v1.split('+').first;
    final v2Clean = v2.split('+').first;

    final parts1 = v1Clean.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final parts2 = v2Clean.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final maxLen = parts1.length > parts2.length ? parts1.length : parts2.length;
    for (int i = 0; i < maxLen; i++) {
      final p1 = i < parts1.length ? parts1[i] : 0;
      final p2 = i < parts2.length ? parts2[i] : 0;
      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  /// True if latest version on Firebase is higher than current app version
  bool isUpdateAvailable(String currentVersion) {
    return compareVersions(latestVersion, currentVersion) > 0;
  }

  /// True if updateRequired flag is set OR current version is lower than minimum version required
  bool isForceUpdateRequired(String currentVersion) {
    if (updateRequired) return true;
    return compareVersions(minimumVersion, currentVersion) > 0;
  }
}
