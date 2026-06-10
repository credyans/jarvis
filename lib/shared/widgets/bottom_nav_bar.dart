import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/shared/widgets/jarvis_fab.dart';

class JarvisBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onJarvisTap;

  const JarvisBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onJarvisTap,
  });

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isActive,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Icon(
                icon,
                color: isActive ? AppColors.primary : AppColors.textPrimary.withOpacity(0.4),
                size: 26.0,
                shadows: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.4),
                          blurRadius: 8.0,
                        )
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 2.0),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 5.0,
              height: 5.0,
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
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          height: 84.0,
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.08),
                width: 1.0,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 32.0,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Tab 0: Today
                _buildNavItem(
                  index: 0,
                  icon: Icons.dashboard_rounded,
                  label: 'Today',
                  isActive: currentIndex == 0,
                ),
                
                // Tab 1: Planner/Focus
                _buildNavItem(
                  index: 1,
                  icon: Icons.calendar_month_rounded,
                  label: 'Planner',
                  isActive: currentIndex == 1,
                ),
                
                // Center Jarvis AI FAB Menu Orb
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: JarvisFab(onTap: onJarvisTap),
                    ),
                  ),
                ),
                
                // Tab 2: Money
                _buildNavItem(
                  index: 2,
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Money',
                  isActive: currentIndex == 2,
                ),
                
                // Tab 3: Memory/Vault
                _buildNavItem(
                  index: 3,
                  icon: Icons.inventory_2_rounded,
                  label: 'Vault',
                  isActive: currentIndex == 3,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
