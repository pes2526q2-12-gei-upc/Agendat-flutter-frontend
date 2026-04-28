import 'package:flutter/material.dart';

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
      title: Text(
        title,
        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/icons/logoAgendat.png',
              height: 40,
              width: 40,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ],
      backgroundColor: Colors.white,
      elevation: 0.0,
      centerTitle: false,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
