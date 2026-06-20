package com.spyear.app

import android.Manifest
import android.bluetooth.BluetoothA2dp
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.bluetooth.BluetoothHeadset
import android.bluetooth.BluetoothManager
import android.bluetooth.BluetoothProfile
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.media.AudioManager
import android.os.Build
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Handles all Bluetooth operations:
 * - Detect connected BT audio device
 * - Enable/disable Bluetooth SCO for low-latency headset routing
 * - Stream BT connection state changes to Flutter
 */
class BluetoothChannel(private val context: Context) :
    MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val audioManager: AudioManager by lazy {
        context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }

    private var eventSink: EventChannel.EventSink? = null
    private var btReceiver: BroadcastReceiver? = null

    // ── MethodChannel Handler ─────────────────────────────────────────────────

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getConnectedDevice"   -> result.success(getConnectedDeviceMap())
            "isBluetoothConnected" -> result.success(isBluetoothAudioConnected())
            "enableBluetoothSco"   -> { enableSco(); result.success(null) }
            "disableBluetoothSco"  -> { disableSco(); result.success(null) }
            else                   -> result.notImplemented()
        }
    }

    // ── EventChannel Handler ──────────────────────────────────────────────────

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
        eventSink = sink
        registerBtReceiver()
        // Emit initial state
        sink?.success(getConnectedDeviceMap())
    }

    override fun onCancel(arguments: Any?) {
        unregisterBtReceiver()
        eventSink = null
    }

    // ── Bluetooth SCO ──────────────────────────────────────────────────────────

    private fun enableSco() {
        audioManager.mode = AudioManager.MODE_IN_COMMUNICATION
        @Suppress("DEPRECATION")
        audioManager.isBluetoothScoOn = true
        @Suppress("DEPRECATION")
        audioManager.startBluetoothSco()
    }

    private fun disableSco() {
        @Suppress("DEPRECATION")
        audioManager.stopBluetoothSco()
        @Suppress("DEPRECATION")
        audioManager.isBluetoothScoOn = false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            audioManager.clearCommunicationDevice()
        }
        audioManager.mode = AudioManager.MODE_NORMAL
    }

    // ── Device Detection ───────────────────────────────────────────────────────

    private fun isBluetoothAudioConnected(): Boolean {
        if (!hasBluetoothPermission()) return false
        val btManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            ?: return false
        val adapter = btManager.adapter ?: return false
        if (!adapter.isEnabled) return false

        return try {
            val connectedDevices = adapter.getProfileConnectionState(BluetoothProfile.HEADSET)
            connectedDevices == BluetoothProfile.STATE_CONNECTED ||
            audioManager.isBluetoothA2dpOn
        } catch (e: SecurityException) {
            false
        }
    }

    private fun getConnectedDeviceMap(): Map<String, Any?>? {
        if (!hasBluetoothPermission()) return null
        val btManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
            ?: return null
        val adapter = btManager.adapter ?: return null
        if (!adapter.isEnabled) return null

        return try {
            // Check A2DP devices
            val a2dpDevices = adapter.bondedDevices?.filter { device ->
                adapter.getProfileConnectionState(BluetoothProfile.A2DP) ==
                        BluetoothProfile.STATE_CONNECTED
            }

            // Check headset (HFP/HSP)
            val headsetDevices = adapter.bondedDevices?.filter { _ ->
                adapter.getProfileConnectionState(BluetoothProfile.HEADSET) ==
                        BluetoothProfile.STATE_CONNECTED
            }

            val device = headsetDevices?.firstOrNull() ?: a2dpDevices?.firstOrNull()
            val isConnected = isBluetoothAudioConnected()

            if (device != null && isConnected) {
                mapOf(
                    "name"        to (device.name ?: "Unknown"),
                    "address"     to device.address,
                    "isConnected" to true,
                    "type"        to if (headsetDevices?.isNotEmpty() == true) "headset" else "headphones"
                )
            } else if (isConnected) {
                // Audio connected but can't get device name
                mapOf(
                    "name"        to "Bluetooth Device",
                    "address"     to "",
                    "isConnected" to true,
                    "type"        to "headset"
                )
            } else {
                mapOf(
                    "name"        to "",
                    "address"     to "",
                    "isConnected" to false,
                    "type"        to "unknown"
                )
            }
        } catch (e: SecurityException) {
            null
        }
    }

    // ── Broadcast Receiver ────────────────────────────────────────────────────

    private fun registerBtReceiver() {
        btReceiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context?, intent: Intent?) {
                // Emit updated device state on BT changes
                eventSink?.success(getConnectedDeviceMap())
            }
        }
        val filter = IntentFilter().apply {
            addAction(BluetoothAdapter.ACTION_STATE_CHANGED)
            addAction(BluetoothAdapter.ACTION_CONNECTION_STATE_CHANGED)
            addAction(BluetoothHeadset.ACTION_CONNECTION_STATE_CHANGED)
            addAction(BluetoothA2dp.ACTION_CONNECTION_STATE_CHANGED)
            addAction(BluetoothDevice.ACTION_ACL_CONNECTED)
            addAction(BluetoothDevice.ACTION_ACL_DISCONNECTED)
            addAction(AudioManager.ACTION_SCO_AUDIO_STATE_UPDATED)
        }
        context.registerReceiver(btReceiver, filter)
    }

    private fun unregisterBtReceiver() {
        btReceiver?.let {
            try { context.unregisterReceiver(it) } catch (_: Exception) {}
        }
        btReceiver = null
    }

    // ── Permission Check ───────────────────────────────────────────────────────

    private fun hasBluetoothPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH_CONNECT) ==
                    PackageManager.PERMISSION_GRANTED
        } else {
            ContextCompat.checkSelfPermission(context, Manifest.permission.BLUETOOTH) ==
                    PackageManager.PERMISSION_GRANTED
        }
    }
}
