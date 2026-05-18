package com.example.share_birds

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.media.audiofx.AcousticEchoCanceler
import android.media.audiofx.AutomaticGainControl
import android.media.audiofx.NoiseSuppressor
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger

/**
 * AudioSharingService — Android Foreground Service
 *
 * Core audio loop: AudioRecord → AudioTrack
 * - Runs in a dedicated thread for lowest possible latency
 * - Supports low-latency mode, gain boost, noise suppression, echo cancellation
 * - Reports live audio level via companion object for platform channel reads
 * - Holds a partial wake lock to keep CPU running when screen is locked
 */
class AudioSharingService : Service() {

    companion object {
        const val ACTION_START           = "START_AUDIO"
        const val ACTION_STOP            = "STOP_AUDIO"
        const val ACTION_APPLY_SETTINGS  = "APPLY_SETTINGS"

        const val EXTRA_LOW_LATENCY      = "low_latency_mode"
        const val EXTRA_GAIN_BOOST       = "gain_boost"
        const val EXTRA_NOISE_SUPPRESS   = "noise_suppression"
        const val EXTRA_ECHO_CANCEL      = "echo_cancellation"

        private const val NOTIFICATION_ID  = 1001
        private const val CHANNEL_ID       = "audio_sharing_channel"

        // Shared audio level (0..32767) — read from AudioChannel
        @Volatile var currentAmplitude: Int = 0
        @Volatile var isRunning: Boolean    = false
    }

    // ── Configuration ─────────────────────────────────────────────────────────

    private var sampleRate      = 44100
    private var channelIn       = AudioFormat.CHANNEL_IN_MONO
    private var channelOut      = AudioFormat.CHANNEL_OUT_MONO
    private var encoding        = AudioFormat.ENCODING_PCM_16BIT

    private var lowLatencyMode  = true
    private var gainBoost       = false
    private var noiseSuppression = false
    private var echoCancellation = false

    // ── State ─────────────────────────────────────────────────────────────────

    private val shouldRun = AtomicBoolean(false)
    private var audioThread: Thread? = null
    private var wakeLock: PowerManager.WakeLock? = null

    // ── Lifecycle ─────────────────────────────────────────────────────────────

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_START -> {
                readSettingsFromIntent(intent)
                startForeground(NOTIFICATION_ID, buildNotification())
                acquireWakeLock()
                startAudioLoop()
            }
            ACTION_STOP -> {
                stopAudioLoop()
                releaseWakeLock()
                stopForeground(STOP_FOREGROUND_REMOVE)
                stopSelf()
            }
            ACTION_APPLY_SETTINGS -> {
                readSettingsFromIntent(intent)
                // Settings will be picked up on next loop iteration
            }
        }
        return START_STICKY
    }

    override fun onDestroy() {
        stopAudioLoop()
        releaseWakeLock()
        isRunning = false
        super.onDestroy()
    }

    // ── Audio Loop ─────────────────────────────────────────────────────────────

    private fun startAudioLoop() {
        if (shouldRun.get()) return
        shouldRun.set(true)
        isRunning = true

        audioThread = Thread({
            android.os.Process.setThreadPriority(android.os.Process.THREAD_PRIORITY_AUDIO)
            runAudioLoop()
        }, "AudioShareThread").also { it.start() }
    }

    private fun stopAudioLoop() {
        shouldRun.set(false)
        isRunning = false
        audioThread?.join(2000)
        audioThread = null
        currentAmplitude = 0
    }

    /**
     * Main audio capture + playback loop.
     * AudioRecord reads PCM frames → AudioTrack writes them to speaker/BT.
     * Using PERFORMANCE_MODE_LOW_LATENCY when lowLatencyMode is enabled.
     */
    private fun runAudioLoop() {
        val bufferSize = calculateBufferSize()
        val audioRecord = buildAudioRecord(bufferSize) ?: return
        val audioTrack  = buildAudioTrack(bufferSize)  ?: run {
            audioRecord.release(); return
        }

        // Attach audio effects if supported
        val ns  = attachNoiseSuppressor(audioRecord.audioSessionId)
        val aec = attachEchoCanceler(audioRecord.audioSessionId)
        val agc = attachGainControl(audioRecord.audioSessionId)

        val buffer = ShortArray(bufferSize / 2)

        try {
            audioRecord.startRecording()
            audioTrack.play()

            while (shouldRun.get()) {
                val read = audioRecord.read(buffer, 0, buffer.size)
                if (read > 0) {
                    // Apply gain boost (simple 2x amplification)
                    if (gainBoost) {
                        for (i in 0 until read) {
                            val amplified = buffer[i].toInt() * 2
                            buffer[i] = amplified.coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt()).toShort()
                        }
                    }

                    // Update amplitude for level meter (RMS of frame)
                    var sum = 0L
                    for (i in 0 until read) sum += buffer[i].toLong() * buffer[i].toLong()
                    currentAmplitude = Math.sqrt((sum / read).toDouble()).toInt()

                    audioTrack.write(buffer, 0, read)
                }
            }
        } finally {
            try { audioRecord.stop() } catch (_: Exception) {}
            try { audioTrack.stop()  } catch (_: Exception) {}
            audioRecord.release()
            audioTrack.release()
            ns?.release()
            aec?.release()
            agc?.release()
            currentAmplitude = 0
        }
    }

    // ── AudioRecord Builder ────────────────────────────────────────────────────

    private fun buildAudioRecord(bufferSize: Int): AudioRecord? {
        val audioSource = if (noiseSuppression)
            MediaRecorder.AudioSource.VOICE_COMMUNICATION
        else
            MediaRecorder.AudioSource.MIC

        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                AudioRecord.Builder()
                    .setAudioSource(audioSource)
                    .setAudioFormat(AudioFormat.Builder()
                        .setEncoding(encoding)
                        .setSampleRate(sampleRate)
                        .setChannelMask(channelIn)
                        .build())
                    .setBufferSizeInBytes(bufferSize)
                    .build()
            } else {
                @Suppress("DEPRECATION")
                AudioRecord(audioSource, sampleRate, channelIn, encoding, bufferSize)
            }
        } catch (e: Exception) {
            null
        }
    }

    // ── AudioTrack Builder ─────────────────────────────────────────────────────

    private fun buildAudioTrack(bufferSize: Int): AudioTrack? {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val performanceMode = if (lowLatencyMode)
                    AudioTrack.PERFORMANCE_MODE_LOW_LATENCY
                else
                    AudioTrack.PERFORMANCE_MODE_NONE

                AudioTrack.Builder()
                    .setAudioAttributes(AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_VOICE_COMMUNICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build())
                    .setAudioFormat(AudioFormat.Builder()
                        .setEncoding(encoding)
                        .setSampleRate(sampleRate)
                        .setChannelMask(channelOut)
                        .build())
                    .setBufferSizeInBytes(bufferSize)
                    .setTransferMode(AudioTrack.MODE_STREAM)
                    .setPerformanceMode(performanceMode)
                    .build()
            } else {
                @Suppress("DEPRECATION")
                AudioTrack(
                    AudioManager.STREAM_VOICE_CALL,
                    sampleRate, channelOut, encoding, bufferSize,
                    AudioTrack.MODE_STREAM
                )
            }
        } catch (e: Exception) {
            null
        }
    }

    // ── Audio Effects ──────────────────────────────────────────────────────────

    private fun attachNoiseSuppressor(sessionId: Int): NoiseSuppressor? {
        if (!noiseSuppression) return null
        return if (NoiseSuppressor.isAvailable()) {
            NoiseSuppressor.create(sessionId)?.also { it.enabled = true }
        } else null
    }

    private fun attachEchoCanceler(sessionId: Int): AcousticEchoCanceler? {
        if (!echoCancellation) return null
        return if (AcousticEchoCanceler.isAvailable()) {
            AcousticEchoCanceler.create(sessionId)?.also { it.enabled = true }
        } else null
    }

    private fun attachGainControl(sessionId: Int): AutomaticGainControl? {
        if (!gainBoost) return null
        return if (AutomaticGainControl.isAvailable()) {
            AutomaticGainControl.create(sessionId)?.also { it.enabled = true }
        } else null
    }

    // ── Buffer Sizing ──────────────────────────────────────────────────────────

    private fun calculateBufferSize(): Int {
        val minBuf = AudioRecord.getMinBufferSize(sampleRate, channelIn, encoding)
        return if (lowLatencyMode) {
            // Use minimum buffer for lowest latency
            maxOf(minBuf, 512)
        } else {
            // Larger buffer for stability
            maxOf(minBuf * 4, 4096)
        }
    }

    // ── Settings ───────────────────────────────────────────────────────────────

    private fun readSettingsFromIntent(intent: Intent) {
        lowLatencyMode  = intent.getBooleanExtra(EXTRA_LOW_LATENCY,    true)
        gainBoost       = intent.getBooleanExtra(EXTRA_GAIN_BOOST,     false)
        noiseSuppression = intent.getBooleanExtra(EXTRA_NOISE_SUPPRESS, false)
        echoCancellation = intent.getBooleanExtra(EXTRA_ECHO_CANCEL,    false)
    }

    // ── Wake Lock ──────────────────────────────────────────────────────────────

    private fun acquireWakeLock() {
        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = pm.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "AudioShareBuds::AudioWakeLock"
        ).also { it.acquire(10 * 60 * 60 * 1000L) } // max 10 hours
    }

    private fun releaseWakeLock() {
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
    }

    // ── Notification ───────────────────────────────────────────────────────────

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Audio Sharing",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Live audio sharing foreground service"
                setShowBadge(false)
                setSound(null, null)
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(): Notification {
        val stopIntent = Intent(this, AudioSharingService::class.java).apply {
            action = ACTION_STOP
        }
        val stopPending = PendingIntent.getService(
            this, 0, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val openIntent = Intent(this, MainActivity::class.java)
        val openPending = PendingIntent.getActivity(
            this, 0, openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("AudioShare Buds")
            .setContentText("🎧 Audio sharing is active")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(openPending)
            .addAction(android.R.drawable.ic_media_pause, "Stop", stopPending)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }
}
