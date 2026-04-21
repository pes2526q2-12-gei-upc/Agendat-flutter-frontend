import 'package:flutter/material.dart';
import 'package:agendat/core/models/event_filters.dart';
import 'package:agendat/core/query/categories_query.dart';
import 'package:agendat/core/query/locations_query.dart';
import 'package:agendat/core/widgets/filter_section.dart';

class SelectedFiltersCard extends StatefulWidget {
  const SelectedFiltersCard({
    super.key,
    this.initialFilters = const EventFilters(),
    this.onApply,
    this.onCancel,
  });

  final EventFilters initialFilters;
  final ValueChanged<EventFilters>? onApply;
  final VoidCallback? onCancel;

  @override
  State<SelectedFiltersCard> createState() => _SelectedFiltersCardState();
}

class _SelectedFiltersCardState extends State<SelectedFiltersCard> {
  final CategoriesQuery _categoriesQuery = CategoriesQuery.instance;
  final LocationsQuery _locationsQuery = LocationsQuery.instance;

  late EventFilters _filters;
  bool _isLoading = true;

  List<String> _categories = [];
  List<String> _provincies = [];
  List<String> _comarques = [];
  List<String> _municipis = [];

  @override
  void initState() {
    super.initState();
    _filters = widget.initialFilters;
    _loadAllOptions();
  }

  Future<void> _loadAllOptions() async {
    try {
      final results = await Future.wait([
        _categoriesQuery.getCategories(),
        _locationsQuery.getProvincies(),
        _loadComarques(_filters.provincia),
        _loadMunicipis(_filters.provincia, _filters.comarca),
      ]);

      if (!mounted) return;

      setState(() {
        _categories = results[0];
        _provincies = results[1];
        _comarques = results[2];
        _municipis = results[3];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<List<String>> _loadComarques(String? provincia) async {
    try {
      return await _locationsQuery.getComarques(provincia: provincia);
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> _loadMunicipis(
    String? provincia,
    String? comarca,
  ) async {
    try {
      return await _locationsQuery.getMunicipis(
        provincia: provincia,
        comarca: comarca,
      );
    } catch (_) {
      return [];
    }
  }

  Future<void> _onProvinciaChanged(String? value) async {
    setState(() {
      _filters = _filters.copyWith(
        provincia: () => value,
        comarca: () => null,
        municipi: () => null,
      );
      _comarques = [];
      _municipis = [];
    });

    final comarques = await _loadComarques(value);
    if (!mounted) return;
    setState(() => _comarques = comarques);
  }

  Future<void> _onComarcaChanged(String? value) async {
    setState(() {
      _filters = _filters.copyWith(comarca: () => value, municipi: () => null);
      _municipis = [];
    });

    final municipis = await _loadMunicipis(_filters.provincia, value);
    if (!mounted) return;
    setState(() => _municipis = municipis);
  }

  void _onClearFilters() {
    setState(() => _filters = const EventFilters());
    _loadAllOptions();
  }

  bool get _hasDateError =>
      _filters.dateFrom != null &&
      _filters.dateTo != null &&
      _filters.dateFrom!.isAfter(_filters.dateTo!);

  void _onApplyPressed() {
    if (_hasDateError) return;
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

  @override
  Widget build(BuildContext context) {
    final hasComarcaAccess = _filters.provincia != null;
    final hasMunicipiAccess =
        _filters.provincia != null && _filters.comarca != null;

    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(40)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtres',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_isLoading) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
            ],

            FilterSection(
              title: 'Categoria',
              options: _categories,
              selectedValue: _filters.category,
              searchable: true,
              allLabel: 'Totes',
              onChanged: (value) {
                setState(() {
                  _filters = _filters.copyWith(category: () => value);
                });
              },
            ),
            const SizedBox(height: 12),

            DateRangeFilterSection(
              dateFrom: _filters.dateFrom,
              dateTo: _filters.dateTo,
              onDateFromChanged: (date) {
                setState(() {
                  _filters = _filters.copyWith(dateFrom: () => date);
                });
              },
              onDateToChanged: (date) {
                setState(() {
                  _filters = _filters.copyWith(dateTo: () => date);
                });
              },
            ),
            const SizedBox(height: 12),

            FilterSection(
              title: 'Província',
              options: _provincies,
              selectedValue: _filters.provincia,
              searchable: true,
              allLabel: 'Totes',
              onChanged: _onProvinciaChanged,
            ),
            const SizedBox(height: 12),

            FilterSection(
              title: 'Comarca',
              options: _comarques,
              selectedValue: _filters.comarca,
              searchable: true,
              allLabel: 'Totes',
              enabled: hasComarcaAccess,
              disabledHint: 'Selecciona una província',
              onChanged: _onComarcaChanged,
            ),
            const SizedBox(height: 12),

            FilterSection(
              title: 'Municipi',
              options: _municipis,
              selectedValue: _filters.municipi,
              searchable: true,
              allLabel: 'Tots',
              enabled: hasMunicipiAccess,
              disabledHint: 'Selecciona una comarca',
              onChanged: (value) {
                setState(() {
                  _filters = _filters.copyWith(municipi: () => value);
                });
              },
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _hasDateError ? null : _onApplyPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A1F1A),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Aplicar filtres'),
              ),
            ),
            const SizedBox(height: 8),

            if (!_filters.isEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _onClearFilters,
                  icon: const Icon(Icons.clear_all, size: 20),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  label: const Text('Netejar filtres'),
                ),
              ),
            if (!_filters.isEmpty) const SizedBox(height: 8),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _onCancelPressed,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Cancel·lar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
