// lib/data/datasources/app_update_datasource.dart
// Datasource for fetching app update info from Firebase Realtime Database

import 'dart:convert';
import 'dart:io';
import '../../domain/entities/app_update_info.dart';

class AppUpdateDatasource {
  static const String _firebaseUrl = 'https://spyear-fd648-default-rtdb.firebaseio.com/apps.json';

  final HttpClient _client;

  AppUpdateDatasource({HttpClient? client}) : _client = client ?? HttpClient();

  /// Fetches update info from Firebase Realtime Database
  Future<AppUpdateInfo?> fetchUpdateInfo({String targetPackageName = 'com.spyear.app'}) async {
    try {
      final request = await _client.getUrl(Uri.parse(_firebaseUrl));
      final response = await request.close();

      if (response.statusCode == HttpStatus.ok) {
        final stringData = await response.transform(utf8.decoder).join();
        final dynamic jsonBody = json.decode(stringData);

        if (jsonBody is List && jsonBody.isNotEmpty) {
          for (final item in jsonBody) {
            if (item is Map<String, dynamic>) {
              final pkg = item['packageName'] as String?;
              if (pkg == targetPackageName || pkg == null) {
                return AppUpdateInfo.fromJson(item);
              }
            }
          }
          // Fallback to first item in array
          if (jsonBody.first is Map<String, dynamic>) {
            return AppUpdateInfo.fromJson(jsonBody.first as Map<String, dynamic>);
          }
        } else if (jsonBody is Map<String, dynamic>) {
          if (jsonBody.containsKey('packageName')) {
            return AppUpdateInfo.fromJson(jsonBody);
          }
          // Handle object map with keys e.g. { "0": { ... } }
          for (final val in jsonBody.values) {
            if (val is Map<String, dynamic>) {
              final pkg = val['packageName'] as String?;
              if (pkg == targetPackageName) {
                return AppUpdateInfo.fromJson(val);
              }
            }
          }
        }
      }
    } catch (e) {
      // Gracefully return null on network error or offline mode
    }
    return null;
  }
}
