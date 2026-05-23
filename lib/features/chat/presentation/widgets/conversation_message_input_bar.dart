import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:agendat/l10n/app_localizations.dart';

/// Camp d'entrada i botó d'enviar per a la conversa.
class ConversationMessageInputBar extends StatelessWidget {
  const ConversationMessageInputBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.pickingImage,
    this.selectedImageBytes,
    required this.onSend,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final bool pickingImage;
  final Uint8List? selectedImageBytes;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  @override
  Widget build(BuildContext context) {
    final disabled = sending || pickingImage;
    final hasSelectedImage = selectedImageBytes != null;
    final selectedBytes = selectedImageBytes;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: hasSelectedImage && selectedBytes != null
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 112,
                    height: 112,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              selectedBytes,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton.filled(
                            tooltip: AppLocalizations.of(context).removeImage,
                            constraints: const BoxConstraints.tightFor(
                              width: 32,
                              height: 32,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: disabled ? null : onRemoveImage,
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  IconButton.filled(
                    onPressed: disabled ? null : onSend,
                    icon: sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              )
            : Row(
                children: [
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) {
                      final hasText = value.text.isNotEmpty;
                      return IconButton(
                        tooltip: AppLocalizations.of(context).addImage,
                        onPressed: disabled || hasText ? null : onPickImage,
                        icon: pickingImage
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.add_photo_alternate_outlined),
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: !disabled,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend(),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context).writeMessageHint,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: disabled ? null : onSend,
                    icon: sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
      ),
    );
  }
}
