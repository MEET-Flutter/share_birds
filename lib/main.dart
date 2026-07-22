// lib/main.dart
// SpyEar — App Entry Point

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_theme.dart';
import 'presentation/splash/splash_screen.dart';
import 'providers/repository_providers.dart';
import 'providers/settings_provider.dart';
import 'providers/tts_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait mode for consistent layout
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar styling for immersive look
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF080C14),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize SharedPreferences before app starts
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        // Inject SharedPreferences into the provider tree
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const AudioShareBudsApp(),
    ),
  );
}

class AudioShareBudsApp extends ConsumerWidget {
  const AudioShareBudsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize TTS + time announcement scheduler at startup
    ref.watch(ttsEngineProvider);
    ref.watch(timeAnnouncementProvider);

    final appSettings = ref.watch(appSettingsProvider).valueOrNull;
    final isDark = appSettings?.isDarkMode ?? true;

    return SafeArea(
      child: MaterialApp(
        title: 'SpyEar',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
        home: const SplashScreen(),
      ),
    );
  }
}
