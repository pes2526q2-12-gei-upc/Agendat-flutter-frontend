import 'package:flutter/material.dart';

class AgendatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AgendatAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(
        "Agenda't",
        style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      elevation: 0.0,
      centerTitle: false,
    );
  }
}
