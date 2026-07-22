// lib/presentation/recordings/recordings_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/recording_provider.dart';

class RecordingsScreen extends ConsumerStatefulWidget {
  const RecordingsScreen({super.key});

  @override
  ConsumerState<RecordingsScreen> createState() => _RecordingsScreenState();
}

class _RecordingsScreenState extends ConsumerState<RecordingsScreen> {
  late final AudioPlayer _audioPlayer;
  String? _currentlyPlayingPath;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  static const List<String> _categories = [
    'All',
    'Earbud Stream',
    'Intercom Relay',
    'Speaker Pass-Through',
    'Voice Note',
  ];

  static const List<String> _dateFilters = [
    'All Time',
    'Today',
    'This Week',
    'This Month',
  ];

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing && state.processingState != ProcessingState.completed;
          if (state.processingState == ProcessingState.completed) {
            _isPlaying = false;
            _position = Duration.zero;
          }
        });
      }
    });

    _audioPlayer.positionStream.listen((pos) {
      if (mounted) {
        setState(() => _position = pos);
      }
    });

    _audioPlayer.durationStream.listen((dur) {
      if (mounted && dur != null) {
        setState(() => _duration = dur);
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playRecording(String path) async {
    try {
      final file = File(path);
      if (!await file.exists() || await file.length() < 44) {
        await ref.read(recordingProvider.notifier).overwriteWithValidWav(file);
      }

      if (_currentlyPlayingPath == path) {
        if (_isPlaying) {
          await _audioPlayer.pause();
        } else {
          await _audioPlayer.play();
        }
      } else {
        await _audioPlayer.stop();
        setState(() {
          _currentlyPlayingPath = path;
          _position = Duration.zero;
          _duration = Duration.zero;
        });
        await _audioPlayer.setAudioSource(AudioSource.uri(Uri.file(file.path)));
        await _audioPlayer.play();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot play file: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Intercom Relay':
        return AppColors.secondary;
      case 'Speaker Pass-Through':
        return AppColors.warningAmber;
      case 'Voice Note':
        return AppColors.liveGreen;
      case 'Earbud Stream':
      default:
        return AppColors.primary;
    }
  }

  String _formatDuration(Duration dur) {
    final m = dur.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = dur.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final recState   = ref.watch(recordingProvider);
    final notifier   = ref.read(recordingProvider.notifier);
    final items      = recState.filteredRecordings;

    final scaffoldBg    = AppColors.getScaffoldBg(context);
    final surfaceBg     = AppColors.getSurfaceBg(context);
    final textPrimary   = AppColors.getTextPrimary(context);
    final textSecondary = AppColors.getTextSecondary(context);
    final border        = AppColors.getBorder(context);
    final primary       = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_rounded, color: primary, size: 22),
            const SizedBox(width: 8),
            Text('Recordings & Library', style: TextStyle(color: textPrimary)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textSecondary),
            onPressed: () => notifier.loadRecordings(),
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Search Bar & Date Filter ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: surfaceBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: border),
                    ),
                    child: TextField(
                      onChanged: (val) => notifier.setSearchQuery(val),
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search recordings...',
                        hintStyle: TextStyle(fontFamily: 'Outfit', fontSize: 13, color: textSecondary),
                        prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 18),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Date Filter Popup Menu
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: surfaceBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: recState.dateFilter,
                      icon: Icon(Icons.filter_list_rounded, color: primary, size: 18),
                      dropdownColor: surfaceBg,
                      style: TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary),
                      onChanged: (val) {
                        if (val != null) notifier.setDateFilter(val);
                      },
                      items: _dateFilters.map((df) {
                        return DropdownMenuItem<String>(
                          value: df,
                          child: Text(df),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Category Chips Bar ──────────────────────────────────────────────
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, idx) {
                final cat = _categories[idx];
                final isSelected = recState.selectedCategory == cat;
                final chipColor = cat == 'All' ? primary : _getCategoryColor(cat);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => notifier.setCategory(cat),
                    backgroundColor: surfaceBg,
                    selectedColor: chipColor.withValues(alpha: 0.2),
                    checkmarkColor: chipColor,
                    labelStyle: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? chipColor : textSecondary,
                    ),
                    side: BorderSide(
                      color: isSelected ? chipColor : border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // ── Active Player Mini Control ──────────────────────────────────────
          if (_currentlyPlayingPath != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surfaceBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primary.withValues(alpha: 0.5)),
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.1),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                          color: primary,
                          size: 36,
                        ),
                        onPressed: () => _playRecording(_currentlyPlayingPath!),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Now Playing',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: primary,
                                letterSpacing: 1.2,
                              ),
                            ),
                            Text(
                              _currentlyPlayingPath!.split('/').last,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: textSecondary, size: 20),
                        onPressed: () async {
                          await _audioPlayer.stop();
                          setState(() {
                            _currentlyPlayingPath = null;
                            _isPlaying = false;
                          });
                        },
                      ),
                    ],
                  ),
                  if (_duration.inMilliseconds > 0) ...[
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        activeTrackColor: primary,
                        inactiveTrackColor: border,
                        thumbColor: primary,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                      ),
                      child: Slider(
                        value: _position.inMilliseconds.clamp(0, _duration.inMilliseconds).toDouble(),
                        max: _duration.inMilliseconds.toDouble(),
                        onChanged: (val) {
                          _audioPlayer.seek(Duration(milliseconds: val.toInt()));
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(_position),
                              style: TextStyle(fontFamily: 'Outfit', fontSize: 10, color: textSecondary)),
                          Text(_formatDuration(_duration),
                              style: TextStyle(fontFamily: 'Outfit', fontSize: 10, color: textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          // ── Recordings List ──────────────────────────────────────────────────
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: surfaceBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: border),
                          ),
                          child: Icon(
                            Icons.folder_open_rounded,
                            size: 28,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Recordings Found',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Connect earbuds or start listening to record.',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final catColor = _getCategoryColor(item.category);
                      final isCurrentPlaying = _currentlyPlayingPath == item.path;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: surfaceBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCurrentPlaying ? primary : border,
                            width: isCurrentPlaying ? 1.5 : 1.0,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: GestureDetector(
                            onTap: () => _playRecording(item.path),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: (isCurrentPlaying && _isPlaying)
                                    ? primary.withValues(alpha: 0.2)
                                    : catColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isCurrentPlaying && _isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: (isCurrentPlaying && _isPlaying) ? primary : catColor,
                                size: 24,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.name,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Category badge tag
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: catColor.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  item.category,
                                  style: TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: catColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${item.formattedDate} • ${item.formattedSize}',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorRed, size: 20),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  backgroundColor: surfaceBg,
                                  title: Text('Delete Recording?', style: TextStyle(color: textPrimary)),
                                  content: Text('Are you sure you want to delete this audio file?', style: TextStyle(color: textSecondary)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: Text('Cancel', style: TextStyle(color: textSecondary)),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Delete', style: TextStyle(color: AppColors.errorRed)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                if (_currentlyPlayingPath == item.path) {
                                  await _audioPlayer.stop();
                                  setState(() {
                                    _currentlyPlayingPath = null;
                                    _isPlaying = false;
                                  });
                                }
                                await notifier.deleteRecording(item.path);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
