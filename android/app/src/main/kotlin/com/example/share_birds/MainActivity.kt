package com.example.share_birds

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity — registers all platform channels with the Flutter engine.
 *
 * Channels registered:
 *   com.example.share_birds/audio    (MethodChannel + EventChannel)
 *   com.example.share_birds/bluetooth (MethodChannel + EventChannel)
 */
class MainActivity : FlutterActivity() {

    private val AUDIO_CHANNEL     = "com.example.share_birds/audio"
    private val AUDIO_LEVEL_EVENT = "com.example.share_birds/audioLevel"
    private val BT_CHANNEL        = "com.example.share_birds/bluetooth"
    private val BT_STATE_EVENT    = "com.example.share_birds/btState"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // ── Audio ─────────────────────────────────────────────────────────────
        val audioChannel = AudioChannel(this)

        MethodChannel(messenger, AUDIO_CHANNEL)
            .setMethodCallHandler(audioChannel)

        EventChannel(messenger, AUDIO_LEVEL_EVENT)
            .setStreamHandler(audioChannel)

        // ── Bluetooth ─────────────────────────────────────────────────────────
        val btChannel = BluetoothChannel(this)

        MethodChannel(messenger, BT_CHANNEL)
            .setMethodCallHandler(btChannel)

        EventChannel(messenger, BT_STATE_EVENT)
            .setStreamHandler(btChannel)
    }
}
