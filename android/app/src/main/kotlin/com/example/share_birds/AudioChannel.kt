package com.example.share_birds
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.Timer
import java.util.TimerTask

/**
 * AudioChannel — bridges Flutter ↔ AudioSharingService
 *
 * MethodChannel: start/stop/isSharing/applySettings
 * EventChannel:  streams normalized audio amplitude (0.0–1.0) every 100ms
 */
class AudioChannel(private val context: Context) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private var levelTimer: Timer? = null
    private var levelSink: EventChannel.EventSink? = null

    // ── MethodChannel ──────────────────────────────────────────────────────────

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startSharing" -> {
                val args = call.arguments as? Map<*, *>
                startService(args)
                result.success(null)
            }
            "stopSharing" -> {
                stopService()
                result.success(null)
            }
            "isSharing" -> {
                result.success(AudioSharingService.isRunning)
            }
            "getAudioLevel" -> {
                val normalized = AudioSharingService.currentAmplitude.toDouble() / 32767.0
                result.success(normalized.coerceIn(0.0, 1.0))
            }
            "applySettings" -> {
                val args = call.arguments as? Map<*, *>
                applySettings(args)
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    // ── EventChannel ──────────────────────────────────────────────────────────

    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
        levelSink = sink
        // Emit audio level every 100ms
        levelTimer = Timer().also { timer ->
            timer.scheduleAtFixedRate(object : TimerTask() {
                override fun run() {
                    val normalized = AudioSharingService.currentAmplitude.toDouble() / 32767.0
                    mainHandler.post {
                        sink?.success(normalized.coerceIn(0.0, 1.0))
                    }
                }
            }, 0L, 100L)
        }
    }

    override fun onCancel(arguments: Any?) {
        levelTimer?.cancel()
        levelTimer = null
        levelSink = null
    }

    // ── Service Control ────────────────────────────────────────────────────────

    private fun startService(args: Map<*, *>?) {
        val intent = Intent(context, AudioSharingService::class.java).apply {
            action = AudioSharingService.ACTION_START
            putExtra(AudioSharingService.EXTRA_LOW_LATENCY,    args?.get("lowLatencyMode")   as? Boolean ?: true)
            putExtra(AudioSharingService.EXTRA_GAIN_BOOST,     args?.get("gainBoost")        as? Boolean ?: false)
            putExtra(AudioSharingService.EXTRA_NOISE_SUPPRESS, args?.get("noiseSuppression") as? Boolean ?: false)
            putExtra(AudioSharingService.EXTRA_ECHO_CANCEL,    args?.get("echoCancellation") as? Boolean ?: false)
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
    }

    private fun stopService() {
        val intent = Intent(context, AudioSharingService::class.java).apply {
            action = AudioSharingService.ACTION_STOP
        }
        context.startService(intent)
    }

    private fun applySettings(args: Map<*, *>?) {
        val intent = Intent(context, AudioSharingService::class.java).apply {
            action = AudioSharingService.ACTION_APPLY_SETTINGS
            putExtra(AudioSharingService.EXTRA_LOW_LATENCY,    args?.get("lowLatencyMode")   as? Boolean ?: true)
            putExtra(AudioSharingService.EXTRA_GAIN_BOOST,     args?.get("gainBoost")        as? Boolean ?: false)
            putExtra(AudioSharingService.EXTRA_NOISE_SUPPRESS, args?.get("noiseSuppression") as? Boolean ?: false)
            putExtra(AudioSharingService.EXTRA_ECHO_CANCEL,    args?.get("echoCancellation") as? Boolean ?: false)
        }
        context.startService(intent)
    }
}
