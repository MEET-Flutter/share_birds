// lib/data/datasources/bluetooth_platform_datasource.dart
// Bridges Dart ↔ Native Kotlin BluetoothChannel via MethodChannel

import 'package:flutter/services.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/failures.dart';

/// Platform channel data source for Bluetooth operations
class BluetoothPlatformDatasource {
  static const _channel = MethodChannel(ChannelNames.bluetooth);
  static const _eventChannel = EventChannel(EventChannelNames.btState);

  /// Returns map with connected device info or null
  Future<Map<String, dynamic>?> getConnectedDevice() async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        BluetoothMethods.getConnectedDevice,
      );
      if (result == null) return null;
      return result.map((k, v) => MapEntry(k.toString(), v));
    } on PlatformException catch (e) {
      throw BluetoothFailure(e.message ?? 'Failed to get BT device');
    }
  }

  /// Returns true if a BT audio device is connected
  Future<bool> isBluetoothConnected() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        BluetoothMethods.isBluetoothConnected,
      );
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Enable Bluetooth SCO for low-latency headset audio routing
  Future<void> enableBluetoothSco() async {
    try {
      await _channel.invokeMethod(BluetoothMethods.enableBluetoothSco);
    } on PlatformException catch (e) {
      throw BluetoothFailure(e.message ?? 'Failed to enable BT SCO');
    }
  }

  /// Disable Bluetooth SCO
  Future<void> disableBluetoothSco() async {
    try {
      await _channel.invokeMethod(BluetoothMethods.disableBluetoothSco);
    } on PlatformException catch (e) {
      throw BluetoothFailure(e.message ?? 'Failed to disable BT SCO');
    }
  }

  /// Stream of BT connection state maps from EventChannel
  Stream<Map<String, dynamic>?> get bluetoothStateStream {
    return _eventChannel.receiveBroadcastStream().map((event) {
      if (event == null) return null;
      if (event is Map) {
        return event.map((k, v) => MapEntry(k.toString(), v));
      }
      return null;
    });
  }
}
