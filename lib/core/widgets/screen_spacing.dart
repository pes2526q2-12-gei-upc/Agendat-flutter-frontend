import 'package:flutter/material.dart';

class AppScreenSpacing {
  static const double horizontal = 20;
  static const double top = 16;
  static const double bottom = 24;

  static const EdgeInsets content = EdgeInsets.fromLTRB(
    horizontal,
    top,
    horizontal,
    bottom,
  );

  static const EdgeInsets contentTightTop = EdgeInsets.fromLTRB(
    horizontal,
    8,
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
