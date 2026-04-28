import 'package:flutter/material.dart';

import 'package:agendat/core/dto/category_dto.dart';
import 'package:agendat/core/query/categories_query.dart';
import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:agendat/features/profile/data/models/user_profile.dart';
import 'package:agendat/features/profile/data/profile_api.dart';
import 'package:agendat/features/profile/data/profile_query.dart';

class EditInterestsScreen extends StatefulWidget {
  const EditInterestsScreen({
    super.key,
    required this.userId,
    required this.currentInterests,
  });

  final int userId;
  final List<UserInterest> currentInterests;

  @override
  State<EditInterestsScreen> createState() => _EditInterestsScreenState();
}

class _EditInterestsScreenState extends State<EditInterestsScreen> {
  final CategoriesQuery _categoriesQuery = CategoriesQuery.instance;
  final ProfileQuery _profileQuery = ProfileQuery.instance;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  List<CategoryDto> _categories = const [];
  late Set<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.currentInterests
        .map((interest) => interest.id)
        .toSet();
    _loadCategories();
  }

  Future<void> _loadCategories({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categories = await _categoriesQuery.getCategoryDtos(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al carregar les categories, refresca la pàgina';
      });
    }
  }

  Future<void> _saveInterests() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final selectedIds = _selectedIds.toList()..sort();
    final result = await _profileQuery.updateInterests(
      widget.userId,
      selectedIds,
    );

    if (!mounted) return;

    switch (result) {
      case UpdateUserInterestsSuccess(:final interests):
        Navigator.of(context).pop(interests);
      case UpdateUserInterestsFailure():
        setState(() => _isSaving = false);
        _showSnackBar(
          'No s\'han pogut guardar les preferències, torna-ho a provar més tard',
        );
    }
  }

  void _toggleCategory(int categoryId) {
    setState(() {
      if (_selectedIds.contains(categoryId)) {
        _selectedIds.remove(categoryId);
      } else {
        _selectedIds.add(categoryId);
      }
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Editar interessos'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _loadCategories(forceRefresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: EventTextUtils.kPrimaryRed,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Refrescar'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 104),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _categories.map(_buildCategoryChip).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: EventTextUtils.kPrimaryRed.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: EventTextUtils.kPrimaryRed,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${_selectedIds.length} seleccionats',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(CategoryDto category) {
    final id = category.id;
    if (id == null) return const SizedBox.shrink();

    final selected = _selectedIds.contains(id);
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected) ...[
            const Icon(Icons.check_rounded, size: 17, color: Colors.white),
            const SizedBox(width: 6),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(category.name, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.grey.shade800,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: EventTextUtils.kPrimaryRed,
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? EventTextUtils.kPrimaryRed : Colors.grey.shade300,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      onSelected: (_) => _toggleCategory(id),
    );
  }

  Widget _buildBottomBar() {
    if (_isLoading || _errorMessage != null) return const SizedBox.shrink();

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveInterests,
          style: ElevatedButton.styleFrom(
            backgroundColor: EventTextUtils.kPrimaryRed,
            foregroundColor: Colors.white,
            disabledBackgroundColor: EventTextUtils.kPrimaryRed.withValues(
              alpha: 0.55,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Guardar',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
        ),
      ),
    );
  }
}
