// lib/core/constants/app_constants.dart
// App-wide constants for AudioShare Buds

/// Channel names for native platform communication
class ChannelNames {
  ChannelNames._();

  static const String audio     = 'com.example.share_birds/audio';
  static const String bluetooth = 'com.example.share_birds/bluetooth';
}

/// Method names for audio platform channel
class AudioMethods {
  AudioMethods._();

  static const String startSharing    = 'startSharing';
  static const String stopSharing     = 'stopSharing';
  static const String getAudioLevel   = 'getAudioLevel';
  static const String applySettings   = 'applySettings';
  static const String isSharing       = 'isSharing';
}

/// Method names for Bluetooth platform channel
class BluetoothMethods {
  BluetoothMethods._();

  static const String getConnectedDevice    = 'getConnectedDevice';
  static const String isBluetoothConnected  = 'isBluetoothConnected';
  static const String enableBluetoothSco    = 'enableBluetoothSco';
  static const String disableBluetoothSco   = 'disableBluetoothSco';
  static const String startDiscovery        = 'startDiscovery';
}

/// Event channel names for continuous data streams
class EventChannelNames {
  EventChannelNames._();

  static const String audioLevel  = 'com.example.share_birds/audioLevel';
  static const String btState     = 'com.example.share_birds/btState';
}

/// Time announcement intervals in minutes
class TimeIntervals {
  TimeIntervals._();

  static const List<int> options = [15, 30, 60];
  static const int defaultInterval = 30;

  static String label(int minutes) {
    if (minutes == 60) return '1 hour';
    return '$minutes min';
  }
}

/// SharedPreferences keys
class PrefKeys {
  PrefKeys._();

  static const String lowLatencyMode    = 'low_latency_mode';
  static const String gainBoost         = 'gain_boost';
  static const String noiseSuppression  = 'noise_suppression';
  static const String echoCancellation  = 'echo_cancellation';
  static const String announceTime      = 'announce_time';
  static const String announceInterval  = 'announce_interval';
}

/// Notification configuration
class NotificationConfig {
  NotificationConfig._();

  static const int notificationId      = 1001;
  static const String channelId        = 'audio_sharing_channel';
  static const String channelName      = 'Audio Sharing';
  static const String channelDesc      = 'Live audio sharing foreground service';
  static const String title            = 'AudioShare Buds';
  static const String contentText      = '🎧 Audio sharing is active';
  static const String stopAction       = 'STOP_SHARING';
}
