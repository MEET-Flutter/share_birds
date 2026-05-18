// lib/data/repositories/bluetooth_repository_impl.dart
// Concrete implementation of BluetoothRepository

import '../../domain/entities/bluetooth_device_entity.dart';
import '../../domain/repositories/bluetooth_repository.dart';
import '../datasources/bluetooth_platform_datasource.dart';

class BluetoothRepositoryImpl implements BluetoothRepository {
  final BluetoothPlatformDatasource _datasource;

  BluetoothRepositoryImpl(this._datasource);

  @override
  Future<BluetoothDeviceEntity?> getConnectedDevice() async {
    final map = await _datasource.getConnectedDevice();
    return map != null ? _fromMap(map) : null;
  }

  @override
  Future<bool> isBluetoothConnected() async {
    return _datasource.isBluetoothConnected();
  }

  @override
  Stream<BluetoothDeviceEntity?> get bluetoothStateStream {
    return _datasource.bluetoothStateStream.map(
      (map) => map != null ? _fromMap(map) : null,
    );
  }

  @override
  Future<void> enableBluetoothSco() async {
    await _datasource.enableBluetoothSco();
  }

  @override
  Future<void> disableBluetoothSco() async {
    await _datasource.disableBluetoothSco();
  }

  /// Parse platform map into domain entity
  BluetoothDeviceEntity _fromMap(Map<String, dynamic> map) {
    return BluetoothDeviceEntity(
      name:        map['name']        as String? ?? 'Unknown Device',
      address:     map['address']     as String? ?? '',
      isConnected: map['isConnected'] as bool?   ?? false,
      type:        _parseType(map['type'] as String?),
    );
  }

  BluetoothDeviceType _parseType(String? type) {
    switch (type) {
      case 'headset':    return BluetoothDeviceType.headset;
      case 'headphones': return BluetoothDeviceType.headphones;
      case 'speaker':    return BluetoothDeviceType.speaker;
      default:           return BluetoothDeviceType.unknown;
    }
  }
}
