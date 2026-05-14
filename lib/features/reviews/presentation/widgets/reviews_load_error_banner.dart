import 'package:flutter/material.dart';

/// Banner inline quan falla la càrrega de valoracions (amb reintent).
class ReviewsLoadErrorBanner extends StatelessWidget {
  const ReviewsLoadErrorBanner({
    super.key,
    required this.brandRed,
    required this.message,
    required this.onRetry,
  });

  final Color brandRed;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: Colors.red.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Tornar a intentar',
              style: TextStyle(color: brandRed, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
