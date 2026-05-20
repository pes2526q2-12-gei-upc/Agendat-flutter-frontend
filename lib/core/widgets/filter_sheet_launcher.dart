import 'package:flutter/material.dart';

/// Shows a filter bottom sheet and returns the selected value (if any).
Future<T?> showFilterBottomSheet<T>({
  required BuildContext context,
  required Widget Function(
    BuildContext sheetContext,
    void Function(T result) apply,
  )
  sheetBuilder,
  ValueChanged<bool>? onSheetVisibilityChanged,
}) async {
  onSheetVisibilityChanged?.call(true);

  final selected = await showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          child: SingleChildScrollView(
            child: sheetBuilder(sheetContext, (result) {
              Navigator.of(sheetContext).pop(result);
            }),
          ),
        ),
      );
    },
  );

  onSheetVisibilityChanged?.call(false);
  return selected;
}
