import 'package:agendat/core/dto/category_dto.dart';
import 'package:agendat/core/query/categories_query.dart';
import 'package:agendat/core/utils/event_text_utils.dart';
import 'package:agendat/core/widgets/screen_spacing.dart';
import 'package:agendat/features/profile/data/profile_api.dart';
import 'package:agendat/features/profile/data/profile_query.dart';
import 'package:flutter/material.dart';

typedef RegisterCategoriesLoader = Future<List<CategoryDto>> Function();
typedef RegisterInterestsSaver =
    Future<bool> Function(int userId, List<int> categoryIds);

class RegisterInterestsScreen extends StatefulWidget {
  const RegisterInterestsScreen({
    super.key,
    required this.userId,
    this.categoriesLoader,
    this.saveInterests,
    this.onFinished,
  });

  static const continueButtonKey = Key('register_interests_continue_button');
  static const skipButtonKey = Key('register_interests_skip_button');
  static Key categoryCardKey(int categoryId) =>
      Key('register_interests_category_card_$categoryId');

  final int userId;
  final RegisterCategoriesLoader? categoriesLoader;
  final RegisterInterestsSaver? saveInterests;
  final VoidCallback? onFinished;

  @override
  State<RegisterInterestsScreen> createState() =>
      _RegisterInterestsScreenState();
}

class _RegisterInterestsScreenState extends State<RegisterInterestsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  List<CategoryDto> _categories = const [];
  final Set<int> _selectedIds = <int>{};

  RegisterCategoriesLoader get _categoriesLoader =>
      widget.categoriesLoader ??
      () => CategoriesQuery.instance.getCategoryDtos(forceRefresh: true);

  RegisterInterestsSaver get _saveInterests =>
      widget.saveInterests ??
      (userId, categoryIds) async {
        final result = await ProfileQuery.instance.updateInterests(
          userId,
          categoryIds,
        );
        return result is UpdateUserInterestsSuccess;
      };

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categories = await _categoriesLoader();
      if (!mounted) return;
      setState(() {
        _categories = categories
            .where(
              (category) => category.id != null && category.name.isNotEmpty,
            )
            .toList();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'No s\'han pogut carregar els interessos.';
      });
    }
  }

  Future<void> _continue() async {
    if (_selectedIds.isEmpty || _isSaving) return;

    setState(() => _isSaving = true);
    final selectedIds = _selectedIds.toList()..sort();
    final saved = await _saveInterests(widget.userId, selectedIds);

    if (!mounted) return;
    if (saved) {
      _finish();
      return;
    }

    setState(() => _isSaving = false);
    _showSnackBar('No s\'han pogut guardar els interessos.');
  }

  void _skip() {
    if (_isSaving) return;
    _finish();
  }

  void _finish() {
    if (widget.onFinished != null) {
      widget.onFinished!();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _toggleCategory(int categoryId) {
    if (_isSaving) return;
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
    final screenHeight = MediaQuery.of(context).size.height;
    final headerHeight = screenHeight * (1 / 3);
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            height: headerHeight,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: EventTextUtils.kPrimaryRed),
                Opacity(
                  opacity: 0.35,
                  child: Image.asset(
                    'assets/icons/Casa-Batlló.jpg',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppScreenSpacing.horizontal,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: _isSaving
                                  ? null
                                  : () => Navigator.of(context).maybePop(),
                              behavior: HitTestBehavior.opaque,
                              child: const Row(
                                children: [
                                  Icon(
                                    Icons.arrow_back_ios_new,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Enrere',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 36,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const _InterestHeaderIcon(),
                              const SizedBox(height: 12),
                              const Text(
                                'Tria els teus interessos',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Personalitza les recomanacions culturals',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _buildBody(
              EdgeInsets.fromLTRB(
                AppScreenSpacing.horizontal,
                24 + padding.top * 0.5,
                AppScreenSpacing.horizontal,
                112 + padding.bottom,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  Widget _buildBody(EdgeInsets padding) {
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
              FilledButton(
                onPressed: _loadCategories,
                style: FilledButton.styleFrom(
                  backgroundColor: EventTextUtils.kPrimaryRed,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Tornar-ho a provar'),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Què t\'interessa?',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Selecciona almenys una categoria per continuar',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              return GridView.builder(
                itemCount: _categories.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  mainAxisExtent: 104,
                ),
                itemBuilder: (context, index) {
                  return _buildCategoryCard(_categories[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(CategoryDto category) {
    final id = category.id;
    if (id == null) return const SizedBox.shrink();

    final selected = _selectedIds.contains(id);
    return Material(
      key: RegisterInterestsScreen.categoryCardKey(id),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _toggleCategory(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? EventTextUtils.kPrimaryRed : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? EventTextUtils.kPrimaryRed
                  : Colors.grey.shade200,
              width: selected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.12 : 0.06),
                blurRadius: selected ? 16 : 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: AnimatedOpacity(
                  opacity: selected ? 1 : 0,
                  duration: const Duration(milliseconds: 120),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _emojiForCategory(category),
                      style: const TextStyle(fontSize: 30, height: 1),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _displayNameForCategory(category.name),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _emojiForCategory(CategoryDto category) {
    final emoji = category.emoji;
    if (emoji != null && emoji.isNotEmpty) return emoji;
    return '✨';
  }

  String _displayNameForCategory(String name) {
    return name
        .split(RegExp(r'[-_]'))
        .where((part) => part.trim().isNotEmpty)
        .map((part) {
          final trimmed = part.trim();
          if (trimmed.isEmpty) return trimmed;
          return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
        })
        .join(' ');
  }

  Widget _buildBottomButtons() {
    if (_isLoading || _errorMessage != null) return const SizedBox.shrink();

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              key: RegisterInterestsScreen.skipButtonKey,
              onPressed: _isSaving ? null : _skip,
              style: OutlinedButton.styleFrom(
                foregroundColor: EventTextUtils.kPrimaryRed,
                side: const BorderSide(color: EventTextUtils.kPrimaryRed),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Saltar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              key: RegisterInterestsScreen.continueButtonKey,
              onPressed: _selectedIds.isEmpty || _isSaving ? null : _continue,
              style: FilledButton.styleFrom(
                backgroundColor: EventTextUtils.kPrimaryRed,
                foregroundColor: Colors.white,
                disabledBackgroundColor: EventTextUtils.kPrimaryRed.withValues(
                  alpha: 0.45,
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Continuar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InterestHeaderIcon extends StatelessWidget {
  const _InterestHeaderIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.favorite_border_rounded,
        color: Colors.white,
        size: 30,
      ),
    );
  }
}
