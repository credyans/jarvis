import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/data/providers/navigation_provider.dart';
import 'package:jarvis/shared/widgets/bottom_nav_bar.dart';
import 'package:jarvis/shared/widgets/gradient_background.dart';
import 'package:jarvis/shared/widgets/jarvis_fab.dart';
import 'package:jarvis/features/today/screens/today_screen.dart';
import 'package:jarvis/features/tasks/screens/focus_screen.dart';
import 'package:jarvis/features/money/screens/money_screen.dart';
import 'package:jarvis/features/memory/screens/memory_screen.dart';
import 'package:jarvis/features/command_bar/command_bar_overlay.dart';
import 'package:jarvis/features/today/widgets/daily_briefing_view.dart';

class AppScaffold extends ConsumerWidget {
  const AppScaffold({super.key});

  Widget _buildSidebarItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
    required ValueChanged<int> onTap,
  }) {
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: isActive ? Colors.white.withOpacity(0.08) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isActive ? Colors.white : Colors.white.withOpacity(0.4),
                size: 26.0,
              ),
            ),
            const SizedBox(height: 4.0),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 6.0,
              height: 6.0,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(currentTabProvider);
    final isCommandBarVisible = ref.watch(commandBarVisibleProvider);
    final briefingCompleted = ref.watch(briefingCompletedProvider);
    final size = MediaQuery.of(context).size;
    final isWidescreen = size.width > 800;

    const List<Widget> screens = [
      TodayScreen(),
      FocusScreen(),
      MoneyScreen(),
      MemoryScreen(),
    ];

    Widget mainContent;

    if (isWidescreen) {
      mainContent = Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Row(
              children: [
                // Desktop Navigation Rail
                Container(
                  width: 96.0,
                  color: AppColors.navBar,
                  child: SafeArea(
                    right: false,
                    child: Column(
                      children: [
                        const SizedBox(height: 24.0),
                        // Jarvis Branding Icon/Logo
                        Container(
                          width: 48.0,
                          height: 48.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.jarvisButtonGradient,
                          ),
                          child: const Center(
                            child: Text(
                              'J',
                              style: TextStyle(
                                fontSize: 22.0,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        // Nav items & Jarvis FAB
                        _buildSidebarItem(
                          index: 0,
                          icon: Icons.wb_sunny_rounded,
                          label: 'Today',
                          isActive: activeTab == 0,
                          onTap: (index) {
                            ref.read(currentTabProvider.notifier).state = index;
                          },
                        ),
                        _buildSidebarItem(
                          index: 1,
                          icon: Icons.check_circle_rounded,
                          label: 'Focus',
                          isActive: activeTab == 1,
                          onTap: (index) {
                            ref.read(currentTabProvider.notifier).state = index;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        JarvisFab(
                          onTap: () {
                            ref.read(commandBarVisibleProvider.notifier).state = true;
                          },
                        ),
                        const SizedBox(height: 16.0),
                        _buildSidebarItem(
                          index: 2,
                          icon: Icons.account_balance_wallet_rounded,
                          label: 'Money',
                          isActive: activeTab == 2,
                          onTap: (index) {
                            ref.read(currentTabProvider.notifier).state = index;
                          },
                        ),
                        _buildSidebarItem(
                          index: 3,
                          icon: Icons.psychology_rounded,
                          label: 'Memory',
                          isActive: activeTab == 3,
                          onTap: (index) {
                            ref.read(currentTabProvider.notifier).state = index;
                          },
                        ),
                        const Spacer(),
                      ],
                    ),
                  ),
                ),
                // Main Content Area with max-width wrapper
                Expanded(
                  child: GradientBackground(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 800.0),
                        child: IndexedStack(
                          index: activeTab,
                          children: screens,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Command Bar Overlay
            if (isCommandBarVisible)
              const CommandBarOverlay(),
          ],
        ),
      );
    } else {
      // Mobile Layout
      mainContent = Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            // Background + Content Screen
            GradientBackground(
              child: IndexedStack(
                index: activeTab,
                children: screens,
              ),
            ),

            // Bottom Navigation Bar
            Positioned(
              left: 0.0,
              right: 0.0,
              bottom: 0.0,
              child: JarvisBottomNavBar(
                currentIndex: activeTab,
                onTap: (index) {
                  ref.read(currentTabProvider.notifier).state = index;
                },
                onJarvisTap: () {
                  ref.read(commandBarVisibleProvider.notifier).state = true;
                },
              ),
            ),

            // Raycast Command Bar Overlay
            if (isCommandBarVisible)
              const CommandBarOverlay(),
          ],
        ),
      );
    }

    return Stack(
      children: [
        mainContent,
        if (!briefingCompleted)
          DailyBriefingView(
            onDismiss: () {
              ref.read(briefingCompletedProvider.notifier).state = true;
            },
          ),
      ],
    );
  }
}
