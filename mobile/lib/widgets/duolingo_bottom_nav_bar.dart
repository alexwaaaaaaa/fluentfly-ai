import 'package:flutter/material.dart';

/// Duolingo-Style Bottom Navigation Bar
/// Features: Simple, clean, colorful icons, smooth animations
class DuolingoBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const DuolingoBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.home_rounded,
              label: 'Learn',
              index: 0,
              color: const Color(0xFF58CC02), // Duolingo green
            ),
            _buildNavItem(
              icon: Icons.emoji_events_rounded,
              label: 'Practice',
              index: 1,
              color: const Color(0xFFFF9600), // Duolingo orange
            ),
            _buildNavItem(
              icon: Icons.leaderboard_rounded,
              label: 'Leaderboard',
              index: 2,
              color: const Color(0xFF1CB0F6), // Duolingo blue
            ),
            _buildNavItem(
              icon: Icons.shopping_bag_rounded,
              label: 'Shop',
              index: 3,
              color: const Color(0xFFFF4B4B), // Duolingo red
            ),
            _buildNavItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              index: 4,
              color: const Color(0xFFCE82FF), // Duolingo purple
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required Color color,
  }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with background
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? color : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
