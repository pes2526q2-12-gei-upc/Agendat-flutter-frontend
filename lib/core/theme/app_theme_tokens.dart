import 'package:flutter/material.dart';

class AppThemeTokens {
  // Colors
  static const Color screenBackground = Color.fromARGB(255, 247, 240, 240);
  static const Color appBarBackground = Colors.white;

  // Typography
  static const TextStyle appBarTitle = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: Colors.black,
  );

  // AppBar
  static const double appBarElevation = 0;
  static const bool appBarCenterTitle = false;
  static const IconThemeData appBarIconTheme = IconThemeData(
    color: Colors.black,
  );
  static const EdgeInsets socialHeaderPadding = EdgeInsets.fromLTRB(
    16,
    4,
    4,
    4,
  );
}
