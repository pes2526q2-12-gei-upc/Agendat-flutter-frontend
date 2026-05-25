import 'package:agendat/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:agendat/core/api/api_error_utils.dart';
import 'package:agendat/core/query/categories_query.dart';
import 'package:agendat/core/widgets/filter_section.dart';
import 'package:agendat/features/map/data/models/map_filters.dart';

class MapFiltersCard extends StatefulWidget {
  const MapFiltersCard({
    super.key,
    required this.initialFilters,
    this.onApply,
    this.onCancel,
  });

  final MapFilters initialFilters;
  final ValueChanged<MapFilters>? onApply;
  final VoidCallback? onCancel;

  @override
  State<MapFiltersCard> createState() => _MapFiltersCardState();
}

class _MapFiltersCardState extends State<MapFiltersCard> {
  final CategoriesQuery _categoriesQuery = CategoriesQuery.instance;

  late MapFilters _filters;
  bool _isLoading = true;
  String? _loadError;
  List<String> _categories = const [];

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _categoriesQuery.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoading = false;
        _loadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = userMessageFromError(
          e,
          fallback: 'No s\'han pogut carregar les categories.',
        );
      });
    }
  }

  void _onCategoryChanged(String? value) {
    setState(() {
      _filters = _filters.copyWith(category: () => value);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filters.date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      confirmText: "D'acord",
      locale: const Locale('ca'),
    );
    if (picked == null) return;
    setState(() {
      _filters = _filters.copyWith(
        date: DateTime(picked.year, picked.month, picked.day),
      );
    });
  }

  void _onResetFilters() {
    setState(() => _filters = MapFilters.today());
  }

  void _onApplyPressed() {
    if (widget.onApply != null) {
      widget.onApply!(_filters);
      return;
    }
    Navigator.of(context).pop(_filters);
  }

  void _onCancelPressed() {
    if (widget.onCancel != null) {
      widget.onCancel!();
      return;
    }
    Navigator.of(context).pop();
  }

  String _formatDate(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.filtersTitle,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_isLoading) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
            ] else if (_loadError != null) ...[
              Text(
                _loadError!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade700),
              ),
              const SizedBox(height: 12),
            ],

            FilterSection(
              title: l10n.category,
              options: _categories,
              selectedValue: _filters.category,
              searchable: true,
              allLabel: l10n.allFeminine,
              onChanged: _onCategoryChanged,
            ),
            const SizedBox(height: 12),

            Text(
              l10n.date,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _MapDateChip(label: _formatDate(_filters.date), onTap: _pickDate),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onApplyPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A1F1A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(l10n.applyFilters),
              ),
            ),
            const SizedBox(height: 8),

            if (!_filters.isDefault)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _onResetFilters,
                  icon: const Icon(Icons.clear_all, size: 20),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  label: Text(l10n.clearFilters),
                ),
              ),
            if (!_filters.isDefault) const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _onCancelPressed,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(l10n.cancel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapDateChip extends StatelessWidget {
  const _MapDateChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: primary),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, size: 18, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
