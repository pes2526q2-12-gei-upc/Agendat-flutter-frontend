import 'package:flutter/material.dart';

class AppSearchBar extends StatelessWidget {
  const AppSearchBar({
    super.key,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.hintText = 'Cerca...',
    this.textInputAction,
    this.suffixIcon,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final String hintText;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: SearchBar(
        controller: controller,
        focusNode: focusNode,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        onTap: onTap,
        hintText: hintText,
        textInputAction: textInputAction,
        leading: const Icon(Icons.search),
        trailing: suffixIcon == null ? null : [suffixIcon!],
        backgroundColor: const WidgetStatePropertyAll(Colors.white),
        constraints: const BoxConstraints(
          minHeight: 56,
          maxWidth: double.infinity,
        ),
        elevation: const WidgetStatePropertyAll(5),
        shadowColor: const WidgetStatePropertyAll(
          Color.fromARGB(255, 204, 117, 126),
        ),
      ),
    );
  }
}
