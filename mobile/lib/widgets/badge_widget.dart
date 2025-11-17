import 'package:flutter/material.dart';
import '../models/badge.dart' as model;

class BadgeWidget extends StatelessWidget {
  final model.Badge badge;
  final double size;

  const BadgeWidget({Key? key, required this.badge, this.size = 80})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF00BFFF), Color(0xFF39FF14)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00BFFF).withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: badge.iconUrl != null
                ? Image.network(
                    badge.iconUrl!,
                    width: size * 0.6,
                    height: size * 0.6,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultIcon(size);
                    },
                  )
                : _buildDefaultIcon(size),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: size + 20,
          child: Text(
            badge.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
        if (badge.description != null)
          SizedBox(
            width: size + 20,
            child: Text(
              badge.description!,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDefaultIcon(double size) {
    return Icon(Icons.emoji_events, size: size * 0.6, color: Colors.white);
  }
}

class BadgeGrid extends StatelessWidget {
  final List<model.Badge> badges;
  final int crossAxisCount;

  const BadgeGrid({Key? key, required this.badges, this.crossAxisCount = 3})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No badges earned yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete lessons to earn badges!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        return BadgeWidget(badge: badges[index]);
      },
    );
  }
}
