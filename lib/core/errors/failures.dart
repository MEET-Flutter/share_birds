// lib/core/errors/failures.dart
// Typed failure classes following clean architecture error handling

/// Base class for all application failures
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Permission was denied by the user
class PermissionFailure extends Failure {
  final String permission;
  const PermissionFailure(this.permission)
      : super('Permission denied: $permission');
}

/// Bluetooth is off or device not connected
class BluetoothFailure extends Failure {
  const BluetoothFailure(super.message);
}

/// Audio engine / platform channel failure
class AudioFailure extends Failure {
  const AudioFailure(super.message);
}

/// Settings read/write failure
class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

/// TTS engine failure
class TtsFailure extends Failure {
  const TtsFailure(super.message);
}

/// Generic / unexpected platform failure
class PlatformFailure extends Failure {
  const PlatformFailure(super.message);
}
