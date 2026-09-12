// test/update_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:share_birds/domain/entities/app_update_info.dart';

void main() {
  group('AppUpdateInfo Version Comparison Tests', () {
    test('compareVersions correctly identifies higher versions', () {
      expect(AppUpdateInfo.compareVersions('1.2.2', '1.2.1'), equals(1));
      expect(AppUpdateInfo.compareVersions('1.3.0', '1.2.1'), equals(1));
      expect(AppUpdateInfo.compareVersions('2.0.0', '1.2.1'), equals(1));
    });

    test('compareVersions correctly identifies lower or equal versions', () {
      expect(AppUpdateInfo.compareVersions('1.2.1', '1.2.1'), equals(0));
      expect(AppUpdateInfo.compareVersions('1.2.0', '1.2.1'), equals(-1));
      expect(AppUpdateInfo.compareVersions('1.1.9', '1.2.1'), equals(-1));
    });

    test('isUpdateAvailable returns true when remote version is higher', () {
      const updateInfo = AppUpdateInfo(
        appName: 'SpyEar',
        packageName: 'com.spyear.app',
        platform: 'android',
        latestVersion: '1.2.2',
        minimumVersion: '1.0.0',
        updateRequired: false,
        updateTitle: 'New Update Available',
        updateMessage: 'Please update to 1.2.2',
        updateUrl: 'https://play.google.com/store/apps/details?id=com.spyear.app',
      );

      expect(updateInfo.isUpdateAvailable('1.2.1'), isTrue);
      expect(updateInfo.isUpdateAvailable('1.2.2'), isFalse);
    });

    test('isForceUpdateRequired checks updateRequired flag and minimumVersion', () {
      const forceUpdate = AppUpdateInfo(
        appName: 'SpyEar',
        packageName: 'com.spyear.app',
        platform: 'android',
        latestVersion: '2.0.0',
        minimumVersion: '1.3.0',
        updateRequired: false,
        updateTitle: 'Critical Update',
        updateMessage: 'Please update immediately',
        updateUrl: 'https://play.google.com/store/apps/details?id=com.spyear.app',
      );

      // 1.2.1 is lower than minimumVersion 1.3.0 -> force update required
      expect(forceUpdate.isForceUpdateRequired('1.2.1'), isTrue);

      const flagForceUpdate = AppUpdateInfo(
        appName: 'SpyEar',
        packageName: 'com.spyear.app',
        platform: 'android',
        latestVersion: '1.2.2',
        minimumVersion: '1.0.0',
        updateRequired: true,
        updateTitle: 'Mandatory Update',
        updateMessage: 'Update required',
        updateUrl: 'https://play.google.com/store/apps/details?id=com.spyear.app',
      );

      expect(flagForceUpdate.isForceUpdateRequired('1.2.1'), isTrue);
    });
  });
}
