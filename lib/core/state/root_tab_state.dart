import 'package:flutter/foundation.dart';

/// Index of the currently selected root tab.
final ValueNotifier<int> rootTabIndexNotifier = ValueNotifier<int>(0);

/// Index of the `Social` tab inside the root navigation.
const int kSocialTabIndex = 3;

/// Index of the `Profile` tab inside the root navigation.
const int kProfileTabIndex = 4;

/// Índex que ocupa la pestanya `Agenda` dins de la navegació arrel.
const int kAgendaTabIndex = 2;
