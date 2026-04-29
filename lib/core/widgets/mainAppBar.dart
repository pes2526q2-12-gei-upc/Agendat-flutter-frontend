import 'package:flutter/material.dart';
import 'package:agendat/core/theme/app_theme_tokens.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;

  const MainAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return AppBar(
      automaticallyImplyLeading: false,
      leading: (showBackButton && canPop) ? const BackButton() : null,
      title: Text(title, style: AppThemeTokens.appBarTitle),
      backgroundColor: AppThemeTokens.appBarBackground,
      iconTheme: AppThemeTokens.appBarIconTheme,
      elevation: AppThemeTokens.appBarElevation,
      centerTitle: AppThemeTokens.appBarCenterTitle,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
