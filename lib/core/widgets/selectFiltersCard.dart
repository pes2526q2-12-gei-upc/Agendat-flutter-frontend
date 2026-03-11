import 'package:flutter/material.dart';
import 'package:agendat/core/services/filters_api_service.dart';
import 'package:agendat/core/utils/event_text_utils.dart';

class SelectedFiltersCard extends StatefulWidget {
  const SelectedFiltersCard({
    super.key,
    this.filterOptions = const {},
    this.initialSelectedFilters,
    this.onFiltersChanged,
    this.onApplyFilters,
    this.onCancel,
    this.showAllOptionWhenEmpty = true,
  });

  final Map<String, List<String>> filterOptions;

  /// Seleccio inicial opcional (per exemple, estat guardat en navegacio).
  final Map<String, List<String>>? initialSelectedFilters;

  /// Callback amb els filtres seleccionats, preparats per enviar a l'API.
  final ValueChanged<Map<String, List<String>>>? onFiltersChanged;
  final ValueChanged<Map<String, List<String>>>? onApplyFilters;
  final VoidCallback? onCancel;
  final bool showAllOptionWhenEmpty;

  @override
  State<SelectedFiltersCard> createState() => _SelectedFiltersCardState();
}

class _SelectedFiltersCardState extends State<SelectedFiltersCard> {
  static const String _allOption = 'Tots';
  static const List<String> _categoryOrder = <String>[
    'Categoria',
    'Data',
    'Ciutat',
    'Municipi',
    'Comarca',
    'Província',
  ];

  final FiltersApiService _filtersApiService = FiltersApiService();

  late Map<String, List<String>> _effectiveFilterOptions;
  late Map<String, String> _selected;
  bool _isLoadingOptions = true;

  @override
  void initState() {
    super.initState();

    final baseOptions = _buildBaseOptions();

    _effectiveFilterOptions = {
      for (final entry in baseOptions.entries)
        entry.key: _withAllOption(entry.value),
    };

    _selected = {
      for (final entry in _effectiveFilterOptions.entries)
        entry.key:
            _resolveInitialSelection(entry.key, entry.value) ?? _allOption,
    };

    _loadOptionsFromApi();
  }

  Future<void> _loadOptionsFromApi() async {
    final optionsFromApi = <String, List<String>>{};

    for (final category in _categoryOrder) {
      if (category == 'Data') {
        optionsFromApi[category] =
            _effectiveFilterOptions[category] ?? const <String>[];
        continue;
      }

      try {
        final options = await _filtersApiService.fetchOptionsForCategory(
          category,
        );
        optionsFromApi[category] = _normalizeOptionsFromApi(options);
      } catch (_) {
        optionsFromApi[category] =
            _effectiveFilterOptions[category] ?? const <String>[];
      }
    }

    if (!mounted) return;

    setState(() {
      _effectiveFilterOptions = {
        for (final category in _categoryOrder)
          category: _withAllOption(
            optionsFromApi[category] ?? const <String>[],
          ),
      };

      _selected = {
        for (final entry in _effectiveFilterOptions.entries)
          entry.key:
              _selected[entry.key] != null &&
                  entry.value.contains(_selected[entry.key])
              ? _selected[entry.key]!
              : _allOption,
      };

      _isLoadingOptions = false;
    });
  }

  Map<String, List<String>> _buildBaseOptions() {
    if (!widget.showAllOptionWhenEmpty && widget.filterOptions.isEmpty) {
      return const <String, List<String>>{};
    }

    final normalizedInput = <String, List<String>>{
      for (final entry in widget.filterOptions.entries)
        entry.key.trim(): entry.value,
    };

    final ordered = <String, List<String>>{};
    for (final category in _categoryOrder) {
      ordered[category] = normalizedInput[category] ?? <String>[];
    }

    for (final entry in normalizedInput.entries) {
      if (!ordered.containsKey(entry.key)) {
        ordered[entry.key] = entry.value;
      }
    }

    return ordered;
  }

  List<String> _withAllOption(List<String> options) {
    final cleaned = options
        .map((option) => option.trim())
        .where((option) => option.isNotEmpty)
        .toList();

    final hasAll = cleaned.any(
      (option) => option.toLowerCase() == _allOption.toLowerCase(),
    );
    if (hasAll) return cleaned;
    return <String>[_allOption, ...cleaned];
  }

  List<String> _normalizeOptionsFromApi(List<String> options) {
    return options
        .map((option) => EventTextUtils.capitalizeFirst(option.replaceAll('-', ' ')))
        .toList();
  }

  String? _resolveInitialSelection(String section, List<String> options) {
    final initial = widget.initialSelectedFilters?[section];
    if (initial == null || initial.isEmpty) return null;

    final selected = initial.first.trim();
    if (selected.isEmpty) return null;

    if (options.contains(selected)) return selected;
    final match = options.where(
      (option) => option.toLowerCase() == selected.toLowerCase(),
    );
    return match.isEmpty ? null : match.first;
  }

  void _onOptionTapped({required String section, required String option}) {
    setState(() {
      _selected[section] = option;
    });

    widget.onFiltersChanged?.call(selectedFiltersForApi);
  }

  Map<String, List<String>> get selectedFiltersForApi {
    return {
      for (final entry in _selected.entries)
        if (entry.value.trim().toLowerCase() != _allOption.toLowerCase())
          entry.key: [entry.value],
    };
  }

  void _onCancelPressed() {
    if (widget.onCancel != null) {
      widget.onCancel!.call();
      return;
    }
    Navigator.of(context).pop();
  }

  void _onApplyPressed() {
    final selected = selectedFiltersForApi;
    widget.onApplyFilters?.call(selected);
    widget.onFiltersChanged?.call(selected);
    Navigator.of(context).pop(selected);
  }

  @override
  Widget build(BuildContext context) {
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
            Text(
              "Filtres",
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_isLoadingOptions) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
            ],
            for (final entry in _effectiveFilterOptions.entries) ...[
              _FilterSection(
                title: entry.key,
                options: entry.value,
                selectedOption: _selected[entry.key] ?? _allOption,
                onOptionTapped: (option) {
                  _onOptionTapped(section: entry.key, option: option);
                },
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 8),
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

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.options,
    required this.selectedOption,
    required this.onOptionTapped,
  });

  final String title;
  final List<String> options;
  final String selectedOption;
  final void Function(String option) onOptionTapped;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: selectedOption == 'Tots' && options.contains('Tots')
              ? null
              : (options.contains(selectedOption) ? selectedOption : null),
          hint: const Text('Selecciona una opció'),
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Text(option, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            onOptionTapped(value);
          },
        ),
      ],
    );
  }
}
