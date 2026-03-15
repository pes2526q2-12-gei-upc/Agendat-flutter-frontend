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
    final resolved = allOptions.contains(displayValue) ? displayValue : allLabel;

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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
    return widget.options
        .where((o) => o.toLowerCase().contains(q))
        .toList();
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

class DateFilterSection extends StatelessWidget {
  const DateFilterSection({
    super.key,
    required this.title,
    this.selectedDate,
    required this.onChanged,
  });

  final String title;
  final DateTime? selectedDate;
  final ValueChanged<DateTime?> onChanged;

  String _formatDisplay(DateTime date) {
    final dd = date.day.toString().padLeft(2, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final yyyy = date.year.toString();
    return '$dd/$mm/$yyyy';
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ca'),
    );
    if (picked != null) onChanged(picked);
  }

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
        InkWell(
          onTap: () => _pickDate(context),
          borderRadius: BorderRadius.circular(4),
          child: InputDecorator(
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              suffixIcon: selectedDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => onChanged(null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  : const Icon(Icons.calendar_today, size: 20),
            ),
            child: Text(
              selectedDate != null
                  ? _formatDisplay(selectedDate!)
                  : 'Sense límit',
              style: TextStyle(
                color: selectedDate != null
                    ? Theme.of(context).textTheme.bodyLarge?.color
                    : Colors.grey,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
