import 'package:flutter/material.dart';

class XpBar extends StatelessWidget {
  final int currentXp;
  final int nextLevelXp;
  final String currentLevel;
  final Color primaryColor;
  final Color accentColor;

  const XpBar({
    Key? key,
    required this.currentXp,
    required this.nextLevelXp,
    required this.currentLevel,
    this.primaryColor = const Color(0xFF00BFFF),
    this.accentColor = const Color(0xFF39FF14),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final progress = (currentXp % nextLevelXp) / nextLevelXp;
    final xpInLevel = currentXp % nextLevelXp;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Level $currentLevel',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            Text(
              '$xpInLevel / $nextLevelXp XP',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                height: 20,
                width: MediaQuery.of(context).size.width * progress,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, accentColor],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static int getNextLevelXp(String level) {
    switch (level) {
      case 'A1':
        return 100;
      case 'A2':
        return 200;
      case 'B1':
        return 300;
      case 'B2':
        return 400;
      case 'C1':
        return 500;
      case 'C2':
        return 500;
      default:
        return 100;
    }
  }
}
