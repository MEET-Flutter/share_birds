// lib/presentation/main_nav_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import 'home/home_screen.dart';
import 'equalizer/equalizer_screen.dart';
import 'recordings/recordings_screen.dart';
import 'settings/settings_screen.dart';

class MainNavScreen extends ConsumerStatefulWidget {
  const MainNavScreen({super.key});

  @override
  ConsumerState<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends ConsumerState<MainNavScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    EqualizerScreen(),
    RecordingsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final bg      = AppColors.getScaffoldBg(context);
    final surface = AppColors.getSurfaceBg(context);
    final border  = AppColors.getBorder(context);
    final primary = Theme.of(context).colorScheme.primary;
    final unselected = AppColors.getTextSecondary(context);

    return Scaffold(
      backgroundColor: bg,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surface,
          border: Border(top: BorderSide(color: border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: surface,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: primary,
          unselectedItemColor: unselected,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.headphones_rounded),
              activeIcon: Icon(Icons.headphones_rounded, color: primary),
              label: 'Listen',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.graphic_eq_rounded),
              activeIcon: Icon(Icons.graphic_eq_rounded, color: primary),
              label: 'Equalizer',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.folder_open_rounded),
              activeIcon: Icon(Icons.folder_open_rounded, color: primary),
              label: 'Recordings',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.tune_rounded),
              activeIcon: Icon(Icons.tune_rounded, color: primary),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
