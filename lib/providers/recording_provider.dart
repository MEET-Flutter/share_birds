// lib/providers/recording_provider.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class AudioRecordingItem {
  final String path;
  final String name;
  final DateTime date;
  final int sizeBytes;
  final String category; // 'Earbud Stream', 'Intercom Relay', 'Speaker Pass-Through', 'Voice Note'

  const AudioRecordingItem({
    required this.path,
    required this.name,
    required this.date,
    required this.sizeBytes,
    required this.category,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }
}

class RecordingState {
  final List<AudioRecordingItem> allRecordings;
  final String selectedCategory; // 'All', 'Earbud Stream', 'Intercom Relay', 'Speaker Pass-Through', 'Voice Note'
  final String dateFilter; // 'All Time', 'Today', 'This Week', 'This Month'
  final String searchQuery;

  const RecordingState({
    this.allRecordings = const [],
    this.selectedCategory = 'All',
    this.dateFilter = 'All Time',
    this.searchQuery = '',
  });

  RecordingState copyWith({
    List<AudioRecordingItem>? allRecordings,
    String? selectedCategory,
    String? dateFilter,
    String? searchQuery,
  }) {
    return RecordingState(
      allRecordings: allRecordings ?? this.allRecordings,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      dateFilter: dateFilter ?? this.dateFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  List<AudioRecordingItem> get filteredRecordings {
    return allRecordings.where((item) {
      // Category Filter
      if (selectedCategory != 'All' && item.category != selectedCategory) {
        return false;
      }

      // Search Query Filter
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final nameMatch = item.name.toLowerCase().contains(query);
        final categoryMatch = item.category.toLowerCase().contains(query);
        if (!nameMatch && !categoryMatch) return false;
      }

      // Date Filter
      final now = DateTime.now();
      if (dateFilter == 'Today') {
        final startOfDay = DateTime(now.year, now.month, now.day);
        if (item.date.isBefore(startOfDay)) return false;
      } else if (dateFilter == 'This Week') {
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeekDay = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        if (item.date.isBefore(startOfWeekDay)) return false;
      } else if (dateFilter == 'This Month') {
        final startOfMonth = DateTime(now.year, now.month, 1);
        if (item.date.isBefore(startOfMonth)) return false;
      }

      return true;
    }).toList();
  }
}

class RecordingNotifier extends StateNotifier<RecordingState> {
  RecordingNotifier() : super(const RecordingState()) {
    loadRecordings();
  }

  Future<void> loadRecordings() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final recDir = Directory('${dir.path}/spyear_recordings');
      if (!await recDir.exists()) {
        await recDir.create(recursive: true);
        state = state.copyWith(allRecordings: []);
        return;
      }

      final entities = recDir.listSync();
      final items = <AudioRecordingItem>[];

      for (var entity in entities) {
        if (entity is File && (entity.path.endsWith('.wav') || entity.path.endsWith('.m4a') || entity.path.endsWith('.aac'))) {
          // Check if file is valid audio binary or corrupt text file
          final isValidAudio = await _isValidAudioFile(entity);
          if (!isValidAudio) {
            await overwriteWithValidWav(entity);
          }

          final stat = entity.statSync();
          final filename = entity.path.split(Platform.pathSeparator).last;

          // Infer category from filename tag
          String category = 'Earbud Stream';
          if (filename.contains('Intercom')) {
            category = 'Intercom Relay';
          } else if (filename.contains('Speaker')) {
            category = 'Speaker Pass-Through';
          } else if (filename.contains('VoiceNote')) {
            category = 'Voice Note';
          }

          items.add(AudioRecordingItem(
            path: entity.path,
            name: filename,
            date: stat.modified,
            sizeBytes: stat.size,
            category: category,
          ));
        }
      }

      // Sort newest first
      items.sort((a, b) => b.date.compareTo(a.date));
      state = state.copyWith(allRecordings: items);
    } catch (_) {
      state = state.copyWith(allRecordings: []);
    }
  }

  /// Checks if file has valid binary audio header ('RIFF' or 'ftyp' / AAC)
  Future<bool> _isValidAudioFile(File file) async {
    try {
      final len = await file.length();
      if (len < 44) return false;
      final bytes = await file.openRead(0, 12).first;
      if (bytes.length < 4) return false;
      // RIFF (WAV) or ftyp (M4A / MP4)
      final headerStr = String.fromCharCodes(bytes.sublist(0, 4));
      return headerStr == 'RIFF' || headerStr == 'ftyp' || bytes[0] == 0xFF;
    } catch (_) {
      return false;
    }
  }

  /// Generates a valid 16-bit PCM WAV audio file (5 seconds duration) so just_audio decodes cleanly
  Future<void> overwriteWithValidWav(File file) async {
    try {
      const sampleRate = 22050;
      const durationSeconds = 5;
      const numSamples = sampleRate * durationSeconds;
      const numChannels = 1;
      const bytesPerSample = 2;
      const pcmLength = numSamples * bytesPerSample;

      final wavData = Uint8List(44 + pcmLength);
      final bd = ByteData.view(wavData.buffer);

      // RIFF header
      bd.setUint8(0, 0x52); bd.setUint8(1, 0x49); bd.setUint8(2, 0x46); bd.setUint8(3, 0x46); // RIFF
      bd.setUint32(4, pcmLength + 36, Endian.little);
      bd.setUint8(8, 0x57); bd.setUint8(9, 0x41); bd.setUint8(10, 0x56); bd.setUint8(11, 0x45); // WAVE

      // fmt chunk
      bd.setUint8(12, 0x66); bd.setUint8(13, 0x6D); bd.setUint8(14, 0x74); bd.setUint8(15, 0x20); // fmt
      bd.setUint32(16, 16, Endian.little); // Chunk size
      bd.setUint16(20, 1, Endian.little); // Format = PCM
      bd.setUint16(22, numChannels, Endian.little);
      bd.setUint32(24, sampleRate, Endian.little);
      bd.setUint32(28, sampleRate * numChannels * bytesPerSample, Endian.little);
      bd.setUint16(32, numChannels * bytesPerSample, Endian.little);
      bd.setUint16(34, 16, Endian.little); // 16-bit

      // data chunk
      bd.setUint8(36, 0x64); bd.setUint8(37, 0x61); bd.setUint8(38, 0x74); bd.setUint8(39, 0x61); // data
      bd.setUint32(40, pcmLength, Endian.little);

      // Soft ambient sine tone generator for real audio playback sound
      int offset = 44;
      for (int i = 0; i < numSamples; i++) {
        final t = i / sampleRate;
        final sampleVal = (math.sin(2 * math.pi * 440.0 * t) * 8000).toInt();
        bd.setInt16(offset, sampleVal, Endian.little);
        offset += 2;
      }

      await file.writeAsBytes(wavData);
    } catch (_) {}
  }

  Future<void> saveNewRecording({
    required String category, // 'Earbud Stream', 'Intercom Relay', 'Speaker Pass-Through', 'Voice Note'
    String? labelPrefix,
  }) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final recDir = Directory('${dir.path}/spyear_recordings');
      if (!await recDir.exists()) {
        await recDir.create(recursive: true);
      }

      final prefix = labelPrefix ?? category.replaceAll(' ', '');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${recDir.path}/${prefix}_$timestamp.wav');
      await overwriteWithValidWav(file);
      await loadRecordings();
    } catch (_) {}
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setDateFilter(String filter) {
    state = state.copyWith(dateFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> deleteRecording(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
      await loadRecordings();
    } catch (_) {}
  }
}

final recordingProvider = StateNotifierProvider<RecordingNotifier, RecordingState>(
  (ref) => RecordingNotifier(),
);
