import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';

import 'package:agendat/core/utils/app_snackbar.dart';
import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/features/profile/presentation/screens/delete_account_screen.dart';
import 'package:agendat/core/models/user_profile.dart';
import 'package:agendat/core/api/profile_api.dart';
import 'package:agendat/core/query/profile_query.dart';
import 'package:agendat/features/profile/presentation/widgets/edit_profile_form_widgets.dart';
import 'package:agendat/l10n/app_localizations.dart';

@visibleForTesting
class ProfileFullNameParts {
  const ProfileFullNameParts({required this.firstName, required this.lastName});

  final String firstName;
  final String lastName;
}

@visibleForTesting
ProfileFullNameParts parseProfileFullName(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+'))
    ..removeWhere((part) => part.isEmpty);

  if (parts.isEmpty) {
    return const ProfileFullNameParts(firstName: '', lastName: '');
  }

  if (parts.length == 1) {
    return ProfileFullNameParts(firstName: parts.first, lastName: '');
  }

  return ProfileFullNameParts(
    firstName: parts.sublist(0, parts.length - 1).join(' '),
    lastName: parts.last,
  );
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.currentProfile});

  final UserProfile currentProfile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _fullNameController;
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _descriptionController;
  final _fullNameFocusNode = FocusNode();
  final _usernameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();

  bool _isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedProfileImage;
  Uint8List? _selectedProfileImageBytes;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: _currentFullName(widget.currentProfile),
    );
    _usernameController = TextEditingController(
      text: widget.currentProfile.username,
    );
    _emailController = TextEditingController(
      text: widget.currentProfile.email ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.currentProfile.description ?? '',
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    _fullNameFocusNode.dispose();
    _usernameFocusNode.dispose();
    _emailFocusNode.dispose();
    _descriptionFocusNode.dispose();
    super.dispose();
  }

  String _currentFullName(UserProfile profile) {
    return [
      profile.firstName,
      profile.lastName,
    ].whereType<String>().where((part) => part.trim().isNotEmpty).join(' ');
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _submitForm() async {
    final l10n = AppLocalizations.of(context);
    final fullName = _fullNameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final description = _descriptionController.text.trim();

    if (username.isEmpty) {
      _showSnackBar(l10n.profileUsernameRequired);
      return;
    }

    if (email.isEmpty) {
      _showSnackBar(l10n.profileEmailRequired);
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnackBar(l10n.profileInvalidEmail);
      return;
    }

    setState(() => _isLoading = true);

    // PATCH parcial: només incloem els camps que han canviat respecte al
    // perfil actual, per no sobreescriure al backend amb valors "stale".
    final current = widget.currentProfile;
    final updates = <String, dynamic>{};
    if (fullName != _currentFullName(current)) {
      final fullNameParts = parseProfileFullName(fullName);
      updates['first_name'] = fullNameParts.firstName;
      updates['last_name'] = fullNameParts.lastName;
    }
    if (username != current.username) updates['username'] = username;
    if (email != (current.email ?? '')) updates['email'] = email;
    if (description != (current.description ?? '')) {
      updates['description'] = description;
    }

    final hasImageChange =
        _selectedProfileImageBytes != null &&
        _selectedProfileImageBytes!.isNotEmpty;

    if (updates.isEmpty && !hasImageChange) {
      setState(() => _isLoading = false);
      Navigator.pop(context, current);
      return;
    }

    final result = await ProfileQuery.instance.updateProfile(
      current.id,
      updates,
      profileImageBytes: _selectedProfileImageBytes,
      profileImageFilename: _selectedProfileImage?.name,
      profileImageContentType: _selectedProfileImage?.mimeType,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    _handleUpdateResult(result);
  }

  void _handleUpdateResult(UpdateProfileResult result) {
    final l10n = AppLocalizations.of(context);
    switch (result) {
      case UpdateProfileSuccess(:final profile):
        _showSnackBar(l10n.profileUpdatedSuccess, isError: false);
        Navigator.pop(context, profile);

      case UpdateProfileValidationError(:final field, :final message):
        if (field == 'email') {
          _showSnackBar(l10n.profileEmailAlreadyRegistered);
        } else if (field == 'username') {
          _showSnackBar(l10n.profileUsernameInvalid);
        } else {
          _showSnackBar(message);
        }

      case UpdateProfileFailure(:final statusCode):
        if (statusCode == -1) {
          _showSnackBar(l10n.profileConnectionError);
        } else {
          _showSnackBar(l10n.profileServerError(statusCode));
        }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    AppSnackBar.show(context, message, isError: isError);
  }

  void _submitWithKeyboard() {
    FocusScope.of(context).unfocus();
    _submitForm();
  }

  Future<void> _pickProfileImage() async {
    final l10n = AppLocalizations.of(context);
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 85,
      );
      if (image == null || !mounted) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() {
        _selectedProfileImage = image;
        _selectedProfileImageBytes = bytes;
      });
    } catch (_) {
      if (!mounted) return;
      _showSnackBar(l10n.profileImageSelectFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(l10n.editProfileTitle),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: AppScreenSpacing.content,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EditProfileFieldLabel(text: l10n.profilePhotoLabel),
            const SizedBox(height: 8),
            Center(
              child: EditProfileAvatarEditor(
                currentProfile: widget.currentProfile,
                selectedImageBytes: _selectedProfileImageBytes,
                isLoading: _isLoading,
                onPickImage: _pickProfileImage,
              ),
            ),
            const SizedBox(height: 24),
            EditProfileFieldLabel(text: l10n.usernameLabel),
            const SizedBox(height: 8),
            EditProfileStyledTextField(
              controller: _usernameController,
              focusNode: _usernameFocusNode,
              hintText: l10n.usernameHint,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                FocusScope.of(context).requestFocus(_fullNameFocusNode);
              },
            ),
            const SizedBox(height: 20),
            EditProfileFieldLabel(text: l10n.fullNameLabel),
            const SizedBox(height: 8),
            EditProfileStyledTextField(
              controller: _fullNameController,
              focusNode: _fullNameFocusNode,
              hintText: l10n.fullNameHint,
              keyboardType: TextInputType.name,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                FocusScope.of(context).requestFocus(_emailFocusNode);
              },
            ),
            const SizedBox(height: 20),
            EditProfileFieldLabel(text: l10n.emailLabel),
            const SizedBox(height: 8),
            EditProfileStyledTextField(
              controller: _emailController,
              focusNode: _emailFocusNode,
              hintText: l10n.emailHint,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onSubmitted: (_) {
                FocusScope.of(context).requestFocus(_descriptionFocusNode);
              },
            ),
            const SizedBox(height: 20),
            EditProfileFieldLabel(text: l10n.descriptionLabel),
            const SizedBox(height: 8),
            EditProfileStyledTextField(
              controller: _descriptionController,
              focusNode: _descriptionFocusNode,
              hintText: l10n.descriptionHint,
              maxLines: 4,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submitWithKeyboard(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        AppSnackBar.show(
                          context,
                          l10n.changePasswordComingSoon,
                        );
                      },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Text(
                  l10n.changePasswordLabel,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DeleteAccountScreen(),
                          ),
                        );
                      },
                icon: const Icon(Icons.delete_outline),
                style: OutlinedButton.styleFrom(
                  foregroundColor: EventTextUtils.kPrimaryRed,
                  side: const BorderSide(color: EventTextUtils.kPrimaryRed),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                label: Text(
                  l10n.deleteAccountButton,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitWithKeyboard,
                style: ElevatedButton.styleFrom(
                  backgroundColor: EventTextUtils.kPrimaryRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        l10n.saveLabel,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
