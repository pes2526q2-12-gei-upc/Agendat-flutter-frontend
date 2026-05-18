import 'package:flutter/material.dart';

import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:agendat/core/dto/category_dto.dart';

class EditInterestsHeaderCard extends StatelessWidget {
  const EditInterestsHeaderCard({super.key, required this.selectedCount});

  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: EventTextUtils.kPrimaryRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: EventTextUtils.kPrimaryRed,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$selectedCount seleccionats',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EditInterestsCategoryChip extends StatelessWidget {
  const EditInterestsCategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onToggle,
  });

  final CategoryDto category;
  final bool selected;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    final id = category.id;
    if (id == null) return const SizedBox.shrink();
    final categoryLabel =
        EventTextUtils.labelOrNull(category.name) ?? category.name;
    final emoji = _emojiForCategory(category);

    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected) ...[
            const Icon(Icons.check_rounded, size: 17, color: Colors.white),
            const SizedBox(width: 6),
          ],
          Text(emoji, style: const TextStyle(fontSize: 17, height: 1)),
          const SizedBox(width: 7),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(categoryLabel, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.grey.shade800,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: EventTextUtils.kPrimaryRed,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? EventTextUtils.kPrimaryRed : Colors.grey.shade300,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onSelected: (_) => onToggle(id),
    );
  }

  String _emojiForCategory(CategoryDto category) {
    final emoji = category.emoji;
    if (emoji != null && emoji.isNotEmpty) return emoji;
    return '✨';
  }
}
