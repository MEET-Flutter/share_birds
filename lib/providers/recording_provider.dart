// lib/providers/recording_provider.dart
import 'dart:io';
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
        if (entity is File && (entity.path.endsWith('.m4a') || entity.path.endsWith('.wav') || entity.path.endsWith('.aac'))) {
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
      final file = File('${recDir.path}/${prefix}_$timestamp.m4a');
      await file.writeAsString('Audio recording session created at ${DateTime.now()}');
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
