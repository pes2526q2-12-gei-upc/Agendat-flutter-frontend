import 'package:flutter/material.dart';
import 'package:agendat/core/widgets/selectFiltersCard.dart';

class FilterButton extends StatelessWidget {
  const FilterButton({
    super.key,
    this.compact = false,
    this.radius = 40.0,
    this.buttonSize = 48.0,
    this.buttonHeight = 48.0,
    this.label = 'Filtres',
    this.onSheetVisibilityChanged,
    this.onApplyFilters,
  });

  final bool compact;
  final double radius;
  final double buttonSize;
  final double? buttonHeight;
  final String label;
  final ValueChanged<bool>? onSheetVisibilityChanged;
  final ValueChanged<Map<String, List<String>>>? onApplyFilters;

  Future<void> _openFilters(BuildContext context) async {
    onSheetVisibilityChanged?.call(true);

    final selectedFilters =
        await showModalBottomSheet<Map<String, List<String>>>(
          // Using modal because it overlays on top of the screen
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (sheetContext) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                child: SingleChildScrollView(
                  child: SelectedFiltersCard(
                    onApply: (selectedFilters) {
                      Navigator.of(sheetContext).pop(selectedFilters);
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

    // Notify that the sheet has been closed
    onSheetVisibilityChanged?.call(false);

    // Apply filters if any
    if (selectedFilters != null) {
      onApplyFilters?.call(selectedFilters);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return SizedBox(
        width: buttonSize,
        height: buttonSize,
        child: FloatingActionButton(
          heroTag: 'filterButton',
          backgroundColor: Colors.white,
          foregroundColor: const Color.fromARGB(255, 149, 31, 22),
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
        backgroundColor: Colors.white,
        foregroundColor: const Color.fromARGB(255, 149, 31, 22),
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
