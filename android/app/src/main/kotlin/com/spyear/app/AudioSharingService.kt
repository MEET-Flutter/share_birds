package com.spyear.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.util.Log
import android.media.AudioAttributes
import android.media.AudioDeviceInfo
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioRecord
import android.media.AudioTrack
import android.media.MediaRecorder
import android.media.audiofx.AcousticEchoCanceler
import android.media.audiofx.AutomaticGainControl
import android.media.audiofx.NoiseSuppressor
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStream
import java.io.RandomAccessFile
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger

/**
 * AudioSharingService — Android Foreground Service
 *
 * Core audio loop: AudioRecord → AudioTrack + optional live WAV PCM file recording
 * - Runs in a dedicated thread for lowest possible latency
 * - Streams live mic audio to AudioTrack and records real microphone PCM audio to WAV file
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
        const val EXTRA_USE_BLUETOOTH_MIC = "use_bluetooth_mic"
        const val EXTRA_PLAY_SPEAKER     = "play_to_phone_speaker"
        const val EXTRA_DUAL_EARBUDS     = "dual_earbud_mode"
        const val EXTRA_RECORDING_PATH   = "recording_path"

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
    private var useBluetoothMic = true
    private var playToPhoneSpeaker = false
    private var dualEarbudMode     = false
    private var recordingPath: String? = null

    // ── File Recording State ──────────────────────────────────────────────────

    private var recordingFile: File? = null
    private var recordingStream: FileOutputStream? = null
    private var totalBytesRecorded: Long = 0

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
        stopRecordingFile()
        audioThread?.join(2000)
        audioThread = null
        currentAmplitude = 0
    }

    /**
     * Main audio capture + playback + live file recording loop.
     */
    private fun runAudioLoop() {
        Log.i("AudioSharingService", "runAudioLoop started: useBluetoothMic=$useBluetoothMic, recordingPath=$recordingPath")
        val bufferSize = calculateBufferSize()
        val audioRecord = buildAudioRecord(bufferSize) ?: run {
            Log.e("AudioSharingService", "Failed to build AudioRecord!")
            return
        }
        
        if (!useBluetoothMic) {
            val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                val cleared = audioManager.clearCommunicationDevice()
                Log.i("AudioSharingService", "clearCommunicationDevice returned: $cleared")
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val devices = audioManager.getDevices(AudioManager.GET_DEVICES_INPUTS)
                val builtInMic = devices.firstOrNull { 
                    it.type == AudioDeviceInfo.TYPE_BUILTIN_MIC
                }
                if (builtInMic != null) {
                    audioRecord.setPreferredDevice(builtInMic)
                }
            }
        }

        val audioTrack  = buildAudioTrack(bufferSize)  ?: run {
            Log.e("AudioSharingService", "Failed to build AudioTrack!")
            audioRecord.release(); return
        }

        // Attach audio effects if supported
        val ns  = attachNoiseSuppressor(audioRecord.audioSessionId)
        val aec = attachEchoCanceler(audioRecord.audioSessionId)
        val agc = attachGainControl(audioRecord.audioSessionId)

        val buffer = ShortArray(bufferSize / 2)

        // Open live file recording if path specified
        recordingPath?.let { path ->
            startRecordingToFile(path)
        }

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

                    // Write live mic PCM audio to WAV file stream
                    recordingStream?.let { fos ->
                        val bytes = ByteArray(read * 2)
                        for (i in 0 until read) {
                            val v = buffer[i].toInt()
                            bytes[i * 2] = (v and 0xff).toByte()
                            bytes[i * 2 + 1] = ((v shr 8) and 0xff).toByte()
                        }
                        try {
                            fos.write(bytes)
                            totalBytesRecorded += bytes.size
                        } catch (e: Exception) {
                            Log.e("AudioSharingService", "Write to recording file failed: $e")
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
            stopRecordingFile()
            currentAmplitude = 0
        }
    }

    // ── Live WAV Recording Functions ──────────────────────────────────────────

    private fun startRecordingToFile(path: String) {
        try {
            stopRecordingFile()
            val file = File(path)
            file.parentFile?.mkdirs()
            val fos = FileOutputStream(file)
            writeWavHeader(fos, sampleRate, 1, 16, 0)
            recordingFile = file
            recordingStream = fos
            totalBytesRecorded = 0
            Log.i("AudioSharingService", "Live WAV recording started: $path")
        } catch (e: Exception) {
            Log.e("AudioSharingService", "Failed to start live recording file: $e")
        }
    }

    private fun stopRecordingFile() {
        try {
            recordingStream?.let { fos ->
                fos.flush()
                fos.close()
                recordingFile?.let { file ->
                    updateWavHeader(file, totalBytesRecorded)
                    Log.i("AudioSharingService", "Live WAV recording finalized: ${file.path}, totalBytes=$totalBytesRecorded")
                }
            }
        } catch (e: Exception) {
            Log.e("AudioSharingService", "Failed to finalize recording file: $e")
        } finally {
            recordingStream = null
            recordingFile = null
            totalBytesRecorded = 0
        }
    }

    private fun writeWavHeader(out: OutputStream, sampleRate: Int, channels: Int, bitsPerSample: Int, pcmDataLength: Long) {
        val header = ByteArray(44)
        val byteRate = sampleRate * channels * bitsPerSample / 8
        val blockAlign = channels * bitsPerSample / 8
        val totalDataLen = pcmDataLength + 36

        header[0] = 'R'.code.toByte(); header[1] = 'I'.code.toByte(); header[2] = 'F'.code.toByte(); header[3] = 'F'.code.toByte()
        header[4] = (totalDataLen and 0xff).toByte()
        header[5] = ((totalDataLen shr 8) and 0xff).toByte()
        header[6] = ((totalDataLen shr 16) and 0xff).toByte()
        header[7] = ((totalDataLen shr 24) and 0xff).toByte()
        header[8] = 'W'.code.toByte(); header[9] = 'A'.code.toByte(); header[10] = 'V'.code.toByte(); header[11] = 'E'.code.toByte()
        header[12] = 'f'.code.toByte(); header[13] = 'm'.code.toByte(); header[14] = 't'.code.toByte(); header[15] = ' '.code.toByte()
        header[16] = 16; header[17] = 0; header[18] = 0; header[19] = 0
        header[20] = 1; header[21] = 0 // PCM
        header[22] = channels.toByte(); header[23] = 0
        header[24] = (sampleRate and 0xff).toByte()
        header[25] = ((sampleRate shr 8) and 0xff).toByte()
        header[26] = ((sampleRate shr 16) and 0xff).toByte()
        header[27] = ((sampleRate shr 24) and 0xff).toByte()
        header[28] = (byteRate and 0xff).toByte()
        header[29] = ((byteRate shr 8) and 0xff).toByte()
        header[30] = ((byteRate shr 16) and 0xff).toByte()
        header[31] = ((byteRate shr 24) and 0xff).toByte()
        header[32] = blockAlign.toByte(); header[33] = 0
        header[34] = bitsPerSample.toByte(); header[35] = 0
        header[36] = 'd'.code.toByte(); header[37] = 'a'.code.toByte(); header[38] = 't'.code.toByte(); header[39] = 'a'.code.toByte()
        header[40] = (pcmDataLength and 0xff).toByte()
        header[41] = ((pcmDataLength shr 8) and 0xff).toByte()
        header[42] = ((pcmDataLength shr 16) and 0xff).toByte()
        header[43] = ((pcmDataLength shr 24) and 0xff).toByte()

        out.write(header, 0, 44)
    }

    private fun updateWavHeader(file: File, pcmDataLength: Long) {
        val raf = RandomAccessFile(file, "rw")
        val totalDataLen = pcmDataLength + 36
        raf.seek(4)
        raf.write(byteArrayOf(
            (totalDataLen and 0xff).toByte(),
            ((totalDataLen shr 8) and 0xff).toByte(),
            ((totalDataLen shr 16) and 0xff).toByte(),
            ((totalDataLen shr 24) and 0xff).toByte()
        ))
        raf.seek(40)
        raf.write(byteArrayOf(
            (pcmDataLength and 0xff).toByte(),
            ((pcmDataLength shr 8) and 0xff).toByte(),
            ((pcmDataLength shr 16) and 0xff).toByte(),
            ((pcmDataLength shr 24) and 0xff).toByte()
        ))
        raf.close()
    }

    // ── AudioRecord Builder ────────────────────────────────────────────────────

    private fun buildAudioRecord(bufferSize: Int): AudioRecord? {
        val audioSource = if (useBluetoothMic) {
            if (noiseSuppression) MediaRecorder.AudioSource.VOICE_COMMUNICATION
            else MediaRecorder.AudioSource.MIC
        } else {
            MediaRecorder.AudioSource.CAMCORDER
        }

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
            Log.e("AudioSharingService", "AudioRecord creation failed: ${e.message}")
            null
        }
    }

    // ── AudioTrack Builder ────────────────────────────────────────────────────

    private fun buildAudioTrack(bufferSize: Int): AudioTrack? {
        val streamType = if (playToPhoneSpeaker) {
            AudioManager.STREAM_MUSIC
        } else if (dualEarbudMode) {
            AudioManager.STREAM_VOICE_CALL
        } else {
            AudioManager.STREAM_MUSIC
        }

        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                AudioTrack.Builder()
                    .setAudioAttributes(AudioAttributes.Builder()
                        .setUsage(if (playToPhoneSpeaker) AudioAttributes.USAGE_MEDIA else AudioAttributes.USAGE_VOICE_COMMUNICATION)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build())
                    .setAudioFormat(AudioFormat.Builder()
                        .setEncoding(encoding)
                        .setSampleRate(sampleRate)
                        .setChannelMask(channelOut)
                        .build())
                    .setBufferSizeInBytes(bufferSize)
                    .setTransferMode(AudioTrack.MODE_STREAM)
                    .setPerformanceMode(
                        if (lowLatencyMode) AudioTrack.PERFORMANCE_MODE_LOW_LATENCY
                        else AudioTrack.PERFORMANCE_MODE_NONE
                    )
                    .build()
            } else {
                @Suppress("DEPRECATION")
                AudioTrack(
                    streamType, sampleRate, channelOut, encoding, bufferSize,
                    AudioTrack.MODE_STREAM
                )
            }
        } catch (e: Exception) {
            Log.e("AudioSharingService", "AudioTrack creation failed: ${e.message}")
            null
        }
    }

    private fun calculateBufferSize(): Int {
        val minRecord = AudioRecord.getMinBufferSize(sampleRate, channelIn, encoding)
        val minTrack  = AudioTrack.getMinBufferSize(sampleRate, channelOut, encoding)
        return Math.max(minRecord, minTrack) * 2
    }

    private fun attachNoiseSuppressor(sessionId: Int): NoiseSuppressor? {
        return if (noiseSuppression && NoiseSuppressor.isAvailable()) {
            NoiseSuppressor.create(sessionId)?.also { it.enabled = true }
        } else null
    }

    private fun attachEchoCanceler(sessionId: Int): AcousticEchoCanceler? {
        return if (echoCancellation && AcousticEchoCanceler.isAvailable()) {
            AcousticEchoCanceler.create(sessionId)?.also { it.enabled = true }
        } else null
    }

    private fun attachGainControl(sessionId: Int): AutomaticGainControl? {
        return if (AutomaticGainControl.isAvailable()) {
            AutomaticGainControl.create(sessionId)?.also { it.enabled = true }
        } else null
    }

    // ── Settings ───────────────────────────────────────────────────────────────

    private fun readSettingsFromIntent(intent: Intent) {
        lowLatencyMode     = intent.getBooleanExtra(EXTRA_LOW_LATENCY,      true)
        gainBoost          = intent.getBooleanExtra(EXTRA_GAIN_BOOST,       false)
        noiseSuppression    = intent.getBooleanExtra(EXTRA_NOISE_SUPPRESS,   false)
        echoCancellation    = intent.getBooleanExtra(EXTRA_ECHO_CANCEL,      false)
        useBluetoothMic     = intent.getBooleanExtra(EXTRA_USE_BLUETOOTH_MIC, true)
        playToPhoneSpeaker  = intent.getBooleanExtra(EXTRA_PLAY_SPEAKER,     false)
        dualEarbudMode      = intent.getBooleanExtra(EXTRA_DUAL_EARBUDS,     false)
        intent.getStringExtra(EXTRA_RECORDING_PATH)?.let { path ->
            recordingPath = path
            if (shouldRun.get()) {
                startRecordingToFile(path)
            }
        }
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
            .setContentText("🎧 Audio sharing & recording active")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setOngoing(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setContentIntent(openPending)
            .addAction(android.R.drawable.ic_media_pause, "Stop", stopPending)
            .setForegroundServiceBehavior(NotificationCompat.FOREGROUND_SERVICE_IMMEDIATE)
            .build()
    }
}
