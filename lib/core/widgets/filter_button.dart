import 'package:flutter/material.dart';
import 'package:agendat/core/widgets/filter_sheet_launcher.dart';
import 'package:agendat/l10n/app_localizations.dart';
import 'package:agendat/core/models/event_filters.dart';
import 'package:agendat/core/widgets/select_filters_card.dart';

class FilterButton extends StatelessWidget {
  const FilterButton({
    super.key,
    this.compact = false,
    this.radius = 40.0,
    this.buttonSize = 48.0,
    this.buttonHeight = 48.0,
    this.label = '',
    this.onSheetVisibilityChanged,
    this.onApplyFilters,
    this.currentFilters = const EventFilters(),
  });

  final bool compact;
  final double radius;
  final double buttonSize;
  final double? buttonHeight;
  final String label;
  final ValueChanged<bool>? onSheetVisibilityChanged;
  final ValueChanged<EventFilters>? onApplyFilters;
  final EventFilters currentFilters;

  Future<void> _openFilters(BuildContext context) async {
    final selectedFilters = await showFilterBottomSheet<EventFilters>(
      context: context,
      onSheetVisibilityChanged: onSheetVisibilityChanged,
      sheetBuilder: (sheetContext, apply) {
        return SelectedFiltersCard(
          initialFilters: currentFilters,
          onApply: apply,
          onCancel: () => Navigator.of(sheetContext).pop(),
        );
      },
    );

    if (selectedFilters != null) {
      onApplyFilters?.call(selectedFilters);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = !currentFilters.isEmpty;

    if (compact) {
      return SizedBox(
        width: buttonSize,
        height: buttonSize,
        child: FloatingActionButton(
          heroTag: 'filterButton',
          backgroundColor: hasActiveFilters
              ? const Color.fromARGB(255, 149, 31, 22)
              : Colors.white,
          foregroundColor: hasActiveFilters
              ? Colors.white
              : const Color.fromARGB(255, 149, 31, 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          onPressed: () => _openFilters(context),
          child: const Icon(Icons.filter_alt_outlined),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: () => _openFilters(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: hasActiveFilters
            ? const Color.fromARGB(255, 149, 31, 22)
            : Colors.white,
        foregroundColor: hasActiveFilters
            ? Colors.white
            : const Color.fromARGB(255, 149, 31, 22),
        minimumSize: buttonHeight == null ? null : Size(0, buttonHeight!),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      icon: const Icon(Icons.filter_alt_outlined),
      label: Text(
        label.isEmpty ? AppLocalizations.of(context).filtersTitle : label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
