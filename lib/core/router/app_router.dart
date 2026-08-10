import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../features/categories/presentation/categories_screen.dart';
import '../../features/favorites/presentation/favorites_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/top50/presentation/top50_screen.dart';
import '../../shared/widgets/dynamic_island_mini_player.dart';
import '../../shared/widgets/floating_pill_navbar.dart';

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  bool _isScrolling = false;
  Timer? _scrollStopTimer;

  final List<ScrollController> _scrollControllers = List.generate(5, (_) => ScrollController());

  @override
  void dispose() {
    _scrollStopTimer?.cancel();
    for (var controller in _scrollControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onScrollNotification(UserScrollNotification notification) {
    if (notification.direction != ScrollDirection.idle) {
      if (!_isScrolling) {
        setState(() {
          _isScrolling = true;
        });
      }
      _scrollStopTimer?.cancel();
      _scrollStopTimer = Timer(const Duration(milliseconds: 700), () {
        if (mounted) {
          setState(() {
            _isScrolling = false;
          });
        }
      });
    }
  }

  void _onNavTap(int index) {
    if (index == _currentIndex) {
      // Re-tapped active tab: Scroll smoothly to top!
      final controller = _scrollControllers[index];
      if (controller.hasClients) {
        controller.animateTo(
          0.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
      }
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(scrollController: _scrollControllers[0]),
      Top50Screen(scrollController: _scrollControllers[1]),
      CategoriesScreen(scrollController: _scrollControllers[2]),
      FavoritesScreen(scrollController: _scrollControllers[3]),
      SettingsScreen(scrollController: _scrollControllers[4]),
    ];

    return Scaffold(
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          _onScrollNotification(notification);
          return false;
        },
        child: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: pages,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: AnimatedScale(
                scale: _isScrolling ? 0.88 : 1.0,
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOutCubic,
                alignment: Alignment.bottomCenter,
                child: AnimatedOpacity(
                  opacity: _isScrolling ? 0.85 : 1.0,
                  duration: const Duration(milliseconds: 220),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const DynamicIslandMiniPlayer(),
                      FloatingPillNavbar(
                        currentIndex: _currentIndex,
                        onTap: _onNavTap,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
