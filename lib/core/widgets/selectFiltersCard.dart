import 'package:flutter/material.dart';
import 'package:agendat/core/services/filters_api_service.dart';
import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:agendat/core/widgets/filter_section.dart';

class SelectedFiltersCard extends StatefulWidget {
  const SelectedFiltersCard({
    super.key,
    this.filterOptions = const {},
    this.onApply,
    this.onCancel,
    this.showAllOptionWhenEmpty = true,
  });

  final Map<String, List<String>> filterOptions;

  final ValueChanged<Map<String, List<String>>>? onApply;
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

    // Inicialitzem l'estat local abans de carregar les opcions dinàmiques.
    final baseOptions = _buildBaseOptions();

    _effectiveFilterOptions = {
      for (final entry in baseOptions.entries)
        entry.key: _withAllOption(entry.value),
    };

    _selected = {for (final category in _categoryOrder) category: _allOption};

    _loadOptionsFromApi();
  }

  // Demanem les opcions de cada categoria
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

      // Si l'usuari ha tocat algun selector abans que acabés la càrrega,
      // conservem la selecció només si encara existeix a la llista final.
      _selected = {
        for (final entry in _effectiveFilterOptions.entries)
          entry.key: _resolveSelectedValue(entry.key, entry.value),
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
        (EventTextUtils.trimmedOrNull(entry.key) ?? entry.key): entry.value,
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
        .map(EventTextUtils.trimmedOrNull)
        .whereType<String>()
        .toList();

    final hasAll = cleaned.any(
      (option) => EventTextUtils.equalsIgnoringCase(option, _allOption),
    );
    if (hasAll) return cleaned;
    return <String>[_allOption, ...cleaned];
  }

  List<String> _normalizeOptionsFromApi(List<String> options) {
    return options.map(EventTextUtils.labelOrNull).whereType<String>().toList();
  }

  String _resolveSelectedValue(String section, List<String> options) {
    final currentValue = _selected[section] ?? _allOption;
    return options.contains(currentValue) ? currentValue : _allOption;
  }

  void _onOptionTapped({required String section, required String option}) {
    setState(() {
      _selected[section] = option;
    });
  }

  // Converteix el formulari al format per l'API
  Map<String, List<String>> get selectedFiltersForApi {
    return {
      for (final entry in _selected.entries)
        if (!EventTextUtils.equalsIgnoringCase(entry.value, _allOption))
          entry.key: [entry.value],
    };
  }

  void _onCancelPressed() {
    // El tancament del modal es delega al callback extern perquè així no depenem
    // del context d'aquest State si el bottom sheet ja s'està desmuntant.
    if (widget.onCancel != null) {
      widget.onCancel!.call();
      return;
    }
    Navigator.of(context).pop();
  }

  void _onApplyPressed() {
    // El formulari només construeix el resultat final. El tancament real del
    // bottom sheet es fa des del callback extern amb el context del modal.
    final selected = selectedFiltersForApi;

    if (widget.onApply != null) {
      widget.onApply!(selected);
      return;
    }

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
            const Text(
              'Filtres',
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_isLoadingOptions) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
            ],
            // Cada secció és una categoria del formulari de filtres
            for (final entry in _effectiveFilterOptions.entries) ...[
              FilterSection(
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
