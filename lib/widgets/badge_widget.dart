import 'package:flutter/material.dart';
import '../models/badge_model.dart';

class BadgeWidget extends StatelessWidget {
  final BadgeModel badge;
  final bool isEarned;
  final VoidCallback? onTap;

  const BadgeWidget({
    Key? key,
    required this.badge,
    this.isEarned = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isEarned ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEarned ? Colors.amber : Colors.grey.shade300,
            width: isEarned ? 2 : 1,
          ),
          boxShadow: isEarned
              ? [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: isEarned ? Colors.amber.withOpacity(0.1) : Colors.grey.shade200,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isEarned ? Colors.amber.withOpacity(0.5) : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  badge.emoji,
                  style: TextStyle(
                    fontSize: 28,
                    color: isEarned ? null : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              badge.name,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isEarned ? Colors.black87 : Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              badge.description,
              style: TextStyle(
                fontSize: 9,
                color: isEarned ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (!isEarned) ...[
              const SizedBox(height: 4),
              Icon(
                Icons.lock_outline,
                size: 14,
                color: Colors.grey.shade400,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class BadgeListTile extends StatelessWidget {
  final BadgeModel badge;
  final bool isEarned;
  final VoidCallback? onTap;

  const BadgeListTile({
    Key? key,
    required this.badge,
    this.isEarned = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isEarned ? Colors.amber.withOpacity(0.2) : Colors.grey.shade100,
          shape: BoxShape.circle,
          border: Border.all(
            color: isEarned ? Colors.amber : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            badge.emoji,
            style: TextStyle(
              fontSize: 24,
              color: isEarned ? null : Colors.grey.shade400,
            ),
          ),
        ),
      ),
      title: Text(
        badge.name,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isEarned ? Colors.black87 : Colors.grey.shade600,
        ),
      ),
      subtitle: Text(
        badge.description,
        style: TextStyle(
          fontSize: 12,
          color: isEarned ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
      ),
      trailing: isEarned
          ? const Icon(Icons.check_circle, color: Colors.green)
          : Icon(Icons.lock_outline, color: Colors.grey.shade400),
    );
  }
}

class BadgeShowcase extends StatelessWidget {
  final List<BadgeModel> earnedBadges;

  const BadgeShowcase({
    Key? key,
    required this.earnedBadges,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (earnedBadges.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.stars_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No badges earned yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start reporting issues to earn badges!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: earnedBadges.length,
        itemBuilder: (context, index) {
          final badge = earnedBadges[index];
          return Container(
            width: 70,
            margin: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      badge.emoji,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  badge.name,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

