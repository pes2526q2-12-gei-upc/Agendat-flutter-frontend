import 'package:flutter/material.dart';

/// Avís quan el xat és només lectura (amic bloquejat, etc.).
class InactiveConversationBanner extends StatelessWidget {
  const InactiveConversationBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.hourglass_disabled_outlined,
                  size: 22,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.35,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
