import 'package:flutter/material.dart';

class AppScreenSpacing {
  // Base spacing scale (8pt grid)
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;

  static const double horizontal = 20;
  static const double top = 16;
  static const double bottom = 24;
  static const double section = md;

  static const EdgeInsets content = EdgeInsets.fromLTRB(
    horizontal,
    top,
    horizontal,
    bottom,
  );

  static const EdgeInsets contentTightTop = EdgeInsets.fromLTRB(
    horizontal,
    xs,
    horizontal,
    bottom,
  );

  static const EdgeInsets contentNoTop = EdgeInsets.fromLTRB(
    horizontal,
    0,
    horizontal,
    bottom,
  );
}
