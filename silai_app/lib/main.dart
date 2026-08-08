import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/trending_screen.dart';
import 'screens/recommend_screen.dart';
import 'screens/blueprint_screen.dart';
import 'screens/aari_screen.dart';
import 'package:video_player_win/video_player_win.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

void main() {
  if (Platform.isWindows) {
    // This registers the Windows-specific video backend
    WidgetsFlutterBinding.ensureInitialized();
    // You might need to call a specific registration if provided by the package
  }
  runApp(const SilaiApp());
}


// void main() {
//   // 1. Ensure Flutter services are bound securely
//   WidgetsFlutterBinding.ensureInitialized();
  
//   // ❌ REMOVE THE LINES BELOW (fvp references)
//   // fvp.registerWith(); 

//   // 3. Apply status bar theme layer styling
//   SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
//     statusBarColor: Colors.transparent,
//     statusBarIconBrightness: Brightness.dark,
//   ));
  
//   // 4. Fire up the actual application core instance
//   runApp(const SilaiApp());
// }

class SilaiApp extends StatelessWidget {
  const SilaiApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Silai',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const MainShell(),
      );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const TrendingScreen(),
    const BlueprintScreen(dressType: "custom design"), 
    const DraftsPlaceholder(),
    const AariScreen(),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
          child: KeyedSubtree(key: ValueKey(_currentIndex), child: _screens[_currentIndex]),
        ),
        bottomNavigationBar: _BottomNav(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
        ),
      );
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
          boxShadow: [BoxShadow(color: Color(0x0F3D2B1F), blurRadius: 16, offset: Offset(0, -4))],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home_rounded, label: 'Home', index: 0, current: currentIndex, onTap: onTap),
                _NavItem(icon: Icons.local_fire_department_outlined, activeIcon: Icons.local_fire_department_rounded, label: 'Trending', index: 1, current: currentIndex, onTap: onTap),
                _ScanNavItem(current: currentIndex, onTap: onTap),
                _NavItem(icon: Icons.book_outlined, activeIcon: Icons.book_rounded, label: 'Drafts', index: 3, current: currentIndex, onTap: onTap),
                _NavItem(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome_rounded, label: 'Aari', index: 4, current: currentIndex, onTap: onTap),
              ],
            ),
          ),
        ),
      );
}

class _NavItem extends StatelessWidget {
  final IconData icon, activeIcon;
  final String label;
  final int index, current;
  final ValueChanged<int> onTap;
  const _NavItem({required this.icon, required this.activeIcon, required this.label, required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.blushLight : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(active ? activeIcon : icon, size: 22, color: active ? AppColors.brick : AppColors.iconMuted),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.w400, color: active ? AppColors.brick : AppColors.iconMuted)),
          ],
        ),
      ),
    );
  }
}

class _ScanNavItem extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _ScanNavItem({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () => onTap(2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.brick,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.brick.withOpacity(0.35), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.content_cut_rounded, color: AppColors.white, size: 22),
            ),
            const SizedBox(height: 3),
            const Text('Stitch', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.brick)),
          ],
        ),
      );
}

class DraftsPlaceholder extends StatelessWidget {
  const DraftsPlaceholder({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: Text('Drafts coming soon', style: TextStyle(color: AppColors.textMuted))),
      );
}