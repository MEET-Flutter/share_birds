// lib/providers/bluetooth_provider.dart
// Riverpod provider for Bluetooth connection state

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/bluetooth_device_entity.dart';
import '../domain/repositories/bluetooth_repository.dart';
import 'repository_providers.dart';

// ── Bluetooth State Notifier ─────────────────────────────────────────────────

class BluetoothNotifier extends StreamNotifier<BluetoothDeviceEntity?> {
  BluetoothRepository get _repo => ref.read(bluetoothRepositoryProvider);

  @override
  Stream<BluetoothDeviceEntity?> build() {
    // Seed with current device, then listen for changes
    _loadInitialDevice();
    return _repo.bluetoothStateStream;
  }

  void _loadInitialDevice() async {
    try {
      final device = await _repo.getConnectedDevice();
      // Only update if stream hasn't emitted yet
      if (state is AsyncLoading) {
        state = AsyncData(device);
      }
    } catch (_) {
      // Silently handle — stream will provide updates
    }
  }

  /// Manually refresh the BT device state
  Future<void> refresh() async {
    final device = await _repo.getConnectedDevice();
    state = AsyncData(device);
  }
}

final bluetoothProvider = StreamNotifierProvider<BluetoothNotifier, BluetoothDeviceEntity?>(
  BluetoothNotifier.new,
);

/// Convenience provider — true if any BT device is connected
final isBluetoothConnectedProvider = Provider<bool>((ref) {
  final btState = ref.watch(bluetoothProvider);
  return btState.valueOrNull?.isConnected ?? false;
});
