import 'package:flutter/material.dart';

class FilterSection extends StatelessWidget {
  const FilterSection({
    super.key,
    required this.title,
    required this.options,
    required this.selectedOption,
    required this.onOptionTapped,
  });

  final String title;
  final List<String> options;
  final String selectedOption;
  final ValueChanged<String> onOptionTapped;

  String? _resolveInitialValue() {
    if (selectedOption == 'Tots' && options.contains('Tots')) return null;
    if (options.contains(selectedOption)) return selectedOption;
    return null;
  }

  List<DropdownMenuItem<String>> _buildItems() {
    return options
        .map(
          (option) => DropdownMenuItem<String>(
            value: option,
            child: Text(option, overflow: TextOverflow.ellipsis),
          ),
        )
        .toList();
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
        DropdownButtonFormField<String>(
          initialValue: _resolveInitialValue(),
          borderRadius: BorderRadius.circular(40),
          hint: const Text('Selecciona una opció'),
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: _buildItems(),
          onChanged: (value) {
            if (value == null) return;
            onOptionTapped(value);
          },
        ),
      ],
    );
  }
}
