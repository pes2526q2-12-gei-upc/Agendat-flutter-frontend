import 'package:flutter/material.dart';

/// Capçalera col·lapsable: títol VALORACIONS, resum (mitjanes) i fletxa.
class ReviewsCollapsibleHeader extends StatelessWidget {
  const ReviewsCollapsibleHeader({
    super.key,
    required this.brandRed,
    required this.reviewCount,
    required this.isExpanded,
    required this.onToggle,
    required this.summary,
  });

  final Color brandRed;
  final int reviewCount;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget summary;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'VALORACIONS ($reviewCount)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: brandRed,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 28,
                  color: brandRed,
                ),
              ],
            ),
            const SizedBox(height: 10),
            summary,
          ],
        ),
      ),
    );
  }
}
