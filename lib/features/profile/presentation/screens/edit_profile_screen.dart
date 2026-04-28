import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:agendat/core/services/baseURL_api.dart';
import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/features/profile/presentation/screens/deleteAccount.dart';
import 'package:agendat/features/profile/data/models/user_profile.dart';
import 'package:agendat/features/profile/data/profile_api.dart';
import 'package:agendat/features/profile/data/profile_query.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.currentProfile});

  final UserProfile currentProfile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _usernameController;
  late final TextEditingController _emailController;
  late final TextEditingController _descriptionController;

  bool _isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _selectedProfileImage;
  Uint8List? _selectedProfileImageBytes;

  @override
  void initState() {
    super.initState();
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
    _usernameController.dispose();
    _emailController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');
    return emailRegex.hasMatch(email);
  }

  Future<void> _submitForm() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final description = _descriptionController.text.trim();

    if (username.isEmpty) {
      _showSnackBar('Introdueix un nom d\'usuari.');
      return;
    }

    if (email.isEmpty) {
      _showSnackBar('Introdueix el correu electrònic.');
      return;
    }

    if (!_isValidEmail(email)) {
      _showSnackBar('Format de correu electrònic no vàlid');
      return;
    }

    setState(() => _isLoading = true);

    // PATCH parcial: només incloem els camps que han canviat respecte al
    // perfil actual, per no sobreescriure al backend amb valors "stale".
    final current = widget.currentProfile;
    final updates = <String, dynamic>{};
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
    switch (result) {
      case UpdateProfileSuccess(:final profile):
        _showSnackBar('Perfil actualitzat correctament', isError: false);
        Navigator.pop(context, profile);

      case UpdateProfileValidationError(:final field, :final message):
        if (field == 'email') {
          _showSnackBar('El correu introduït ja està registrat al sistema');
        } else if (field == 'username') {
          _showSnackBar('Nom d\'usuari no vàlid');
        } else {
          _showSnackBar(message);
        }

      case UpdateProfileFailure(:final statusCode):
        if (statusCode == -1) {
          _showSnackBar('Error de connexió. Comprova la teva connexió.');
        } else {
          _showSnackBar('Error del servidor (codi $statusCode).');
        }
    }
  }

  void _showSnackBar(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? null : Colors.green.shade700,
      ),
    );
  }

  Future<void> _pickProfileImage() async {
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
      _showSnackBar('No s\'ha pogut seleccionar la imatge');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Editar perfil'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: AppScreenSpacing.content,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Foto de perfil'),
            const SizedBox(height: 8),
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  _buildAvatar(),
                  Positioned(
                    right: -6,
                    bottom: -6,
                    child: Material(
                      color: EventTextUtils.kPrimaryRed,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _isLoading ? null : _pickProfileImage,
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
            ),
            const SizedBox(height: 24),
            _buildLabel('Nom d\'usuari'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _usernameController,
              hintText: 'El teu nom d\'usuari',
            ),
            const SizedBox(height: 20),
            _buildLabel('Correu electrònic'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _emailController,
              hintText: 'exemple@correu.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),
            _buildLabel('Descripció'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _descriptionController,
              hintText: 'Escriu una descripció sobre tu...',
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('pendent')),
                        );
                      },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: const Text(
                  'Canviar contrasenya',
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
                label: const Text(
                  'Eliminar perfil',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitForm,
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
                    : const Text(
                        'Desar canvis',
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

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
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

  Widget _buildAvatar() {
    const radius = 52.0;
    const size = radius * 2;

    if (_selectedProfileImageBytes != null &&
        _selectedProfileImageBytes!.isNotEmpty) {
      return ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Image.memory(
            _selectedProfileImageBytes!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildAvatarFallback(radius),
          ),
        ),
      );
    }

    final imageUrl = resolveProfileImageUrl(widget.currentProfile.profileImage);
    if (imageUrl == null) return _buildAvatarFallback(radius);

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          webHtmlElementStrategy: kIsWeb
              ? WebHtmlElementStrategy.prefer
              : WebHtmlElementStrategy.never,
          errorBuilder: (_, __, ___) => _buildAvatarFallback(radius),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(double radius) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey.shade200,
      child: Icon(Icons.person, size: 56, color: Colors.grey.shade400),
    );
  }
}
