// lib/providers/update_provider.dart
// Riverpod provider for checking app updates from Firebase Realtime Database

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/datasources/app_update_datasource.dart';
import '../domain/entities/app_update_info.dart';

final appUpdateDatasourceProvider = Provider<AppUpdateDatasource>((ref) {
  return AppUpdateDatasource();
});

/// Current installed version of the app
const String currentAppVersion = '1.2.1';

/// Provider that asynchronously checks for available app updates
final appUpdateCheckProvider = FutureProvider.autoDispose<AppUpdateInfo?>((ref) async {
  final datasource = ref.watch(appUpdateDatasourceProvider);
  return await datasource.fetchUpdateInfo();
});
