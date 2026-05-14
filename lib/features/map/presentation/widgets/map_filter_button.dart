import 'package:flutter/material.dart';
import 'package:agendat/features/map/presentation/models/map_filters.dart';
import 'package:agendat/features/map/presentation/widgets/map_filters_card.dart';

/// Map-only filter button that opens the [MapFiltersCard] sheet.
class MapFilterButton extends StatelessWidget {
  const MapFilterButton({
    super.key,
    required this.currentFilters,
    this.onApplyFilters,
    this.onSheetVisibilityChanged,
    this.compact = true,
    this.radius = 40.0,
    this.buttonSize = 48.0,
    this.buttonHeight = 48.0,
    this.label = 'Filtres',
  });

  final MapFilters currentFilters;
  final ValueChanged<MapFilters>? onApplyFilters;
  final ValueChanged<bool>? onSheetVisibilityChanged;
  final bool compact;
  final double radius;
  final double buttonSize;
  final double? buttonHeight;
  final String label;

  Future<void> _openFilters(BuildContext context) async {
    onSheetVisibilityChanged?.call(true);

    final selectedFilters = await showModalBottomSheet<MapFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            child: SingleChildScrollView(
              child: MapFiltersCard(
                initialFilters: currentFilters,
                onApply: (filters) {
                  Navigator.of(sheetContext).pop(filters);
                },
                onCancel: () {
                  Navigator.of(sheetContext).pop();
                },
              ),
            ),
          ),
        );
      },
    );

    onSheetVisibilityChanged?.call(false);

    if (selectedFilters != null) {
      onApplyFilters?.call(selectedFilters);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = !currentFilters.isDefault;

    if (compact) {
      return SizedBox(
        width: buttonSize,
        height: buttonSize,
        child: FloatingActionButton(
          heroTag: 'mapFilterButton',
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
      label: Text(label),
    );
  }
}
