// lib/domain/repositories/bluetooth_repository.dart
// Abstract interface for Bluetooth operations

import '../entities/bluetooth_device_entity.dart';

/// Contract for Bluetooth operations — implemented in the data layer
abstract class BluetoothRepository {
  /// Returns the currently connected Bluetooth audio device (or null)
  Future<BluetoothDeviceEntity?> getConnectedDevice();

  /// Returns true if a Bluetooth audio device is connected
  Future<bool> isBluetoothConnected();

  /// Stream of BT connection state changes
  Stream<BluetoothDeviceEntity?> get bluetoothStateStream;

  /// Enables Bluetooth SCO (low-latency headset profile)
  Future<void> enableBluetoothSco();

  /// Disables Bluetooth SCO
  Future<void> disableBluetoothSco();
}
