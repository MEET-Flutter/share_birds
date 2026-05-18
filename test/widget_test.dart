// test/widget_test.dart
// Smoke and layout test for AudioShare Buds application

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:share_birds/main.dart';
import 'package:share_birds/providers/repository_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // ── Mock Platform Channels to prevent MissingPluginException ────────────
    
    // Audio Platform Channel Mock
    const MethodChannel('com.example.share_birds/audio')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'isSharing') return false;
      return null;
    });

    // Bluetooth Platform Channel Mock
    const MethodChannel('com.example.share_birds/bluetooth')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getConnectedDevice') return null;
      return null;
    });

    // Text to Speech Mock
    const MethodChannel('flutter_tts')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      return null;
    });

    // System Navigation Bar Mock
    const MethodChannel('flutter/platform')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      return null;
    });
  });

  testWidgets('AudioShare Buds App Launches and Renders Successfully', (WidgetTester tester) async {
    // Mock initial preferences
    SharedPreferences.setMockInitialValues({
      'low_latency_mode': true,
      'announcement_interval': 30,
      'gain_boost': false,
    });

    final prefs = await SharedPreferences.getInstance();

    // Pump the app with Riverpod Scope and Mocked SharedPreferences
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const AudioShareBudsApp(),
      ),
    );

    // Trigger initial state frames
    await tester.pumpAndSettle();

    // Verify key UI text items are rendered
    expect(find.text('AudioShare Buds'), findsWidgets);
    expect(find.text('Live Audio Monitor'), findsOneWidget);
    expect(find.text('Start Sharing'), findsOneWidget);
    expect(find.text('SETTINGS'), findsOneWidget);
  });
}
