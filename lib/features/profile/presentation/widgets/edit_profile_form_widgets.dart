import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:agendat/core/utils/profile_image_url.dart';
import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:agendat/core/models/user_profile.dart';
import 'package:agendat/core/widgets/avatars.dart';

class EditProfileFieldLabel extends StatelessWidget {
  const EditProfileFieldLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }
}

class EditProfileStyledTextField extends StatelessWidget {
  const EditProfileStyledTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.maxLines = 1,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final int maxLines;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: maxLines == 1 ? keyboardType : TextInputType.multiline,
      obscureText: obscureText,
      maxLines: maxLines,
      textInputAction: maxLines == 1
          ? textInputAction
          : TextInputAction.newline,
      onSubmitted: maxLines == 1 ? onSubmitted : null,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey.shade400),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: EventTextUtils.kPrimaryRed, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

class EditProfileAvatarEditor extends StatelessWidget {
  const EditProfileAvatarEditor({
    super.key,
    required this.currentProfile,
    required this.selectedImageBytes,
    required this.isLoading,
    required this.onPickImage,
  });

  final UserProfile currentProfile;
  final Uint8List? selectedImageBytes;
  final bool isLoading;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _AvatarPreview(
            currentProfile: currentProfile,
            selectedImageBytes: selectedImageBytes,
          ),
          Positioned(
            right: -6,
            bottom: -6,
            child: Material(
              color: EventTextUtils.kPrimaryRed,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: isLoading ? null : onPickImage,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.currentProfile,
    required this.selectedImageBytes,
  });

  final UserProfile currentProfile;
  final Uint8List? selectedImageBytes;

  static const _radius = 52.0;
  static const _size = _radius * 2;

  @override
  Widget build(BuildContext context) {
    final avatar = selectedImageBytes != null && selectedImageBytes!.isNotEmpty
        ? ClipOval(
            child: SizedBox(
              width: _size,
              height: _size,
              child: Image.memory(
                selectedImageBytes!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _fallback(),
              ),
            ),
          )
        : () {
            final imageUrl = resolveProfileImageUrl(
              currentProfile.profileImage,
            );
            if (imageUrl == null) return _fallback();

            return ClipOval(
              child: SizedBox(
                width: _size,
                height: _size,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  webHtmlElementStrategy: kIsWeb
                      ? WebHtmlElementStrategy.prefer
                      : WebHtmlElementStrategy.never,
                  errorBuilder: (_, __, ___) => _fallback(),
                ),
              ),
            );
          }();

    return AvatarLevelRing(reputation: currentProfile.reputacio, child: avatar);
  }

  Widget _fallback() {
    return CircleAvatar(
      radius: _radius,
      backgroundColor: Colors.grey.shade200,
      child: Icon(Icons.person, size: 56, color: Colors.grey.shade400),
    );
  }
}
