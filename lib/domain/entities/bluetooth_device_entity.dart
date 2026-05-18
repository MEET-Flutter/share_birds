// lib/domain/entities/bluetooth_device_entity.dart
// Bluetooth device domain entity

/// Represents a connected Bluetooth audio device
class BluetoothDeviceEntity {
  final String name;
  final String address;
  final bool isConnected;
  final BluetoothDeviceType type;

  const BluetoothDeviceEntity({
    required this.name,
    required this.address,
    required this.isConnected,
    this.type = BluetoothDeviceType.headset,
  });

  BluetoothDeviceEntity copyWith({
    String? name,
    String? address,
    bool? isConnected,
    BluetoothDeviceType? type,
  }) {
    return BluetoothDeviceEntity(
      name:        name        ?? this.name,
      address:     address     ?? this.address,
      isConnected: isConnected ?? this.isConnected,
      type:        type        ?? this.type,
    );
  }

  @override
  String toString() => 'BluetoothDeviceEntity(name: $name, address: $address, isConnected: $isConnected)';
}

enum BluetoothDeviceType {
  headset,    // HFP/HSP — lower latency, mono
  headphones, // A2DP — higher quality, stereo
  speaker,
  unknown,
}
