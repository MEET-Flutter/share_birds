// test/widget_test.dart
// Smoke and layout test for SpyEar application

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:share_birds/main.dart';
import 'package:share_birds/providers/repository_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    // Audio Platform Channel Mock
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.spyear.app/audio'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'isSharing') return false;
        return null;
      },
    );

    // Bluetooth Platform Channel Mock
    messenger.setMockMethodCallHandler(
      const MethodChannel('com.spyear.app/bluetooth'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getConnectedDevice') return null;
        return null;
      },
    );

    // Text to Speech Mock
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (MethodCall methodCall) async {
        return null;
      },
    );
  });

  testWidgets('SpyEar App Launches and Renders Successfully', (WidgetTester tester) async {
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

    // Trigger initial state frames and advance past splash screen timer & route transition
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3500));
    await tester.pump(const Duration(milliseconds: 700));

    // Verify key UI text items are rendered
    expect(find.text('SpyEar'), findsWidgets);
    expect(find.text('Start Sharing'), findsOneWidget);
    expect(find.text('BLUETOOTH DEVICE'), findsOneWidget);
    expect(find.text('MICROPHONE SOURCE'), findsOneWidget);
  });
}
