import 'package:flutter/material.dart';

class FilterSection extends StatelessWidget {
  const FilterSection({
    super.key,
    required this.title,
    required this.options,
    this.selectedValue,
    required this.onChanged,
    this.enabled = true,
    this.allLabel = 'Tots',
    this.searchable = false,
    this.disabledHint,
  });

  final String title;
  final List<String> options;
  final String? selectedValue;
  final ValueChanged<String?> onChanged;
  final bool enabled;
  final String allLabel;
  final bool searchable;
  final String? disabledHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (searchable)
          _SearchableField(
            options: options,
            selectedValue: selectedValue,
            allLabel: allLabel,
            enabled: enabled,
            disabledHint: disabledHint,
            onChanged: onChanged,
          )
        else
          _DropdownField(
            options: options,
            selectedValue: selectedValue,
            allLabel: allLabel,
            enabled: enabled,
            onChanged: onChanged,
          ),
      ],
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.options,
    this.selectedValue,
    required this.allLabel,
    required this.enabled,
    required this.onChanged,
  });

  final List<String> options;
  final String? selectedValue;
  final String allLabel;
  final bool enabled;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final displayValue = selectedValue ?? allLabel;
    final allOptions = [allLabel, ...options];
    final resolved = allOptions.contains(displayValue)
        ? displayValue
        : allLabel;

    return DropdownButtonFormField<String>(
      initialValue: resolved,
      borderRadius: BorderRadius.circular(12),
      isExpanded: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      items: allOptions.map((option) {
        return DropdownMenuItem<String>(
          value: option,
          child: Text(option, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: enabled
          ? (value) => onChanged(value == allLabel ? null : value)
          : null,
    );
  }
}

class _SearchableField extends StatelessWidget {
  const _SearchableField({
    required this.options,
    this.selectedValue,
    required this.allLabel,
    required this.enabled,
    this.disabledHint,
    required this.onChanged,
  });

  final List<String> options;
  final String? selectedValue;
  final String allLabel;
  final bool enabled;
  final String? disabledHint;
  final ValueChanged<String?> onChanged;

  Future<void> _showSearchDialog(BuildContext context) async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _OptionSearchDialog(
        options: options,
        selectedValue: selectedValue,
        allLabel: allLabel,
      ),
    );
    if (result == null) return;
    onChanged(result == allLabel ? null : result);
  }

  @override
  Widget build(BuildContext context) {
    final displayText = !enabled
        ? (disabledHint ?? allLabel)
        : (selectedValue ?? allLabel);

    final textColor = enabled
        ? Theme.of(context).textTheme.bodyLarge?.color
        : Theme.of(context).disabledColor;

    return InkWell(
      onTap: enabled ? () => _showSearchDialog(context) : null,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          suffixIcon: Icon(
            Icons.arrow_drop_down,
            color: enabled ? null : Theme.of(context).disabledColor,
          ),
          enabled: enabled,
        ),
        child: Text(
          displayText,
          style: TextStyle(color: textColor),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _OptionSearchDialog extends StatefulWidget {
  const _OptionSearchDialog({
    required this.options,
    this.selectedValue,
    required this.allLabel,
  });

  final List<String> options;
  final String? selectedValue;
  final String allLabel;

  @override
  State<_OptionSearchDialog> createState() => _OptionSearchDialogState();
}

class _OptionSearchDialogState extends State<_OptionSearchDialog> {
  String _query = '';

  List<String> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return widget.options.where((o) => o.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
          maxWidth: 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Cerca...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const Divider(height: 1),
            ListTile(
              dense: true,
              title: Text(
                widget.allLabel,
                style: TextStyle(
                  fontWeight: widget.selectedValue == null
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              selected: widget.selectedValue == null,
              onTap: () => Navigator.pop(context, widget.allLabel),
            ),
            const Divider(height: 1),
            Flexible(
              child: _filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Cap resultat',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final option = _filtered[i];
                        final isSelected = option == widget.selectedValue;
                        return ListTile(
                          dense: true,
                          title: Text(
                            option,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          onTap: () => Navigator.pop(context, option),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class DateRangeFilterSection extends StatelessWidget {
  const DateRangeFilterSection({
    super.key,
    this.dateFrom,
    this.dateTo,
    required this.onDateFromChanged,
    required this.onDateToChanged,
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final ValueChanged<DateTime?> onDateFromChanged;
  final ValueChanged<DateTime?> onDateToChanged;

  bool get _hasError =>
      dateFrom != null && dateTo != null && dateFrom!.isAfter(dateTo!);

  String _format(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
  }

  DateTime _clamp(DateTime date, DateTime first, DateTime last) {
    if (date.isBefore(first)) return first;
    if (date.isAfter(last)) return last;
    return date;
  }

  Future<void> _pickFrom(BuildContext context) async {
    final first = DateTime(2020);
    final last = dateTo ?? DateTime(2030);
    final picked = await showDatePicker(
      context: context,
      initialDate: _clamp(dateFrom ?? DateTime.now(), first, last),
      firstDate: first,
      lastDate: last,
      locale: const Locale('ca'),
    );
    if (picked != null) onDateFromChanged(picked);
  }

  Future<void> _pickTo(BuildContext context) async {
    final first = dateFrom ?? DateTime(2020);
    final last = DateTime(2030);
    final picked = await showDatePicker(
      context: context,
      initialDate: _clamp(dateTo ?? DateTime.now(), first, last),
      firstDate: first,
      lastDate: last,
      locale: const Locale('ca'),
    );
    if (picked != null) onDateToChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dates',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _DateChip(
                label: dateFrom != null ? _format(dateFrom!) : 'Inici',
                hasValue: dateFrom != null,
                hasError: _hasError,
                onTap: () => _pickFrom(context),
                onClear: dateFrom != null
                    ? () => onDateFromChanged(null)
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Icon(
                Icons.arrow_forward,
                size: 18,
                color: _hasError ? errorColor : Colors.grey,
              ),
            ),
            Expanded(
              child: _DateChip(
                label: dateTo != null ? _format(dateTo!) : 'Fi',
                hasValue: dateTo != null,
                hasError: _hasError,
                onTap: () => _pickTo(context),
                onClear: dateTo != null ? () => onDateToChanged(null) : null,
              ),
            ),
          ],
        ),
        if (_hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'La data d\'inici ha de ser anterior a la data fi',
              style: TextStyle(color: errorColor, fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.hasValue,
    required this.hasError,
    required this.onTap,
    this.onClear,
  });

  final String label;
  final bool hasValue;
  final bool hasError;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final borderColor = hasError
        ? Theme.of(context).colorScheme.error
        : (hasValue
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade400);

    return Material(
      color: hasValue
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: hasValue
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: hasValue
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onClear != null)
                GestureDetector(
                  onTap: onClear,
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
