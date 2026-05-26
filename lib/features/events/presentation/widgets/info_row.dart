import 'package:flutter/material.dart';

/// Fila d'informació amb icona, etiqueta en negreta i valor.
/// Usat a la vista de detall d'un esdeveniment.
class InfoRow extends StatefulWidget {
  const InfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.collapsedMaxLines = 4,
  });

  final IconData icon;
  final String label;
  final String value;
  final int collapsedMaxLines;

  static const _accentColor = Color.fromARGB(255, 202, 3, 3);
  static const _textStyle = TextStyle(fontSize: 14, color: Colors.black87);

  @override
  State<InfoRow> createState() => _InfoRowState();
}

class _InfoRowState extends State<InfoRow> {
  bool _expanded = false;

  TextSpan _valueSpan() {
    return TextSpan(
      style: InfoRow._textStyle,
      children: [
        TextSpan(
          text: '${widget.label}: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        TextSpan(text: widget.value),
      ],
    );
  }

  bool _exceedsCollapsedMaxLines(double maxWidth) {
    final painter = TextPainter(
      text: _valueSpan(),
      maxLines: widget.collapsedMaxLines,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: maxWidth);
    return painter.didExceedMaxLines;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(widget.icon, size: 20, color: InfoRow._accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final exceedsMaxLines = _exceedsCollapsedMaxLines(
                  constraints.maxWidth,
                );
                final showToggle = exceedsMaxLines || _expanded;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      _valueSpan(),
                      softWrap: true,
                      maxLines: _expanded ? null : widget.collapsedMaxLines,
                      overflow: _expanded
                          ? TextOverflow.visible
                          : TextOverflow.ellipsis,
                    ),
                    if (showToggle) ...[
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          setState(() => _expanded = !_expanded);
                        },
                        child: Text(
                          _expanded ? 'Veure menys' : 'Veure més',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: InfoRow._accentColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
