import 'package:flutter/material.dart';
import 'package:agendat/core/models/event_filters.dart';
import 'package:agendat/core/services/categories_api_service.dart';
import 'package:agendat/core/services/locations_api_service.dart';
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
  final CategoriesApiService _categoriesApi = CategoriesApiService();
  final LocationsApiService _locationsApi = LocationsApiService();

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
        _categoriesApi.fetchCategories(),
        _locationsApi.fetchProvincies(),
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
      if (provincia != null) {
        return await _locationsApi.fetchComarques(provincia: provincia);
      }
      return await _locationsApi.fetchComarques();
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> _loadMunicipis(
    String? provincia,
    String? comarca,
  ) async {
    try {
      return await _locationsApi.fetchMunicipis(
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
      _filters = _filters.copyWith(
        comarca: () => value,
        municipi: () => null,
      );
      _municipis = [];
    });

    final municipis = await _loadMunicipis(_filters.provincia, value);
    if (!mounted) return;
    setState(() => _municipis = municipis);
  }

  void _onClearFilters() {
    setState(() {
      _filters = const EventFilters();
    });
    _loadAllOptions();
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

            // Category
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

            // Date range
            Row(
              children: [
                Expanded(
                  child: DateFilterSection(
                    title: 'Data des de',
                    selectedDate: _filters.dateFrom,
                    onChanged: (date) {
                      setState(() {
                        _filters = _filters.copyWith(dateFrom: () => date);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DateFilterSection(
                    title: 'Data fins a',
                    selectedDate: _filters.dateTo,
                    onChanged: (date) {
                      setState(() {
                        _filters = _filters.copyWith(dateTo: () => date);
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Província
            FilterSection(
              title: 'Província',
              options: _provincies,
              selectedValue: _filters.provincia,
              searchable: true,
              allLabel: 'Totes',
              onChanged: _onProvinciaChanged,
            ),
            const SizedBox(height: 12),

            // Comarca
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

            // Municipi
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

            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onApplyPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7A1F1A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Aplicar filtres'),
              ),
            ),
            const SizedBox(height: 8),

            // Clear filters button
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

            // Cancel button
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
