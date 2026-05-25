import 'package:flutter/foundation.dart';

/// Index of the currently selected root tab.
final ValueNotifier<int> rootTabIndexNotifier = ValueNotifier<int>(0);

/// Emitted every time the user taps a root tab, including re-taps.
final ValueNotifier<RootTabActivation> rootTabActivationNotifier =
    ValueNotifier<RootTabActivation>(
      const RootTabActivation(index: 0, sequence: 0),
    );

class RootTabActivation {
  const RootTabActivation({required this.index, required this.sequence});

  final int index;
  final int sequence;
}

/// Index of the `Home` tab inside the root navigation.
const int kHomeTabIndex = 0;

/// Index of the `Map` tab inside the root navigation.
const int kMapTabIndex = 1;

/// Index of the `Agenda` tab inside the root navigation.
const int kAgendaTabIndex = 2;

/// Index of the `Social` tab inside the root navigation.
const int kSocialTabIndex = 3;

/// Index of the `Profile` tab inside the root navigation.
const int kProfileTabIndex = 4;

void setSelectedRootTabIndex(int index) {
  if (rootTabIndexNotifier.value == index) return;
  rootTabIndexNotifier.value = index;
}

void notifyRootTabActivated(int index) {
  setSelectedRootTabIndex(index);
  final current = rootTabActivationNotifier.value;
  rootTabActivationNotifier.value = RootTabActivation(
    index: index,
    sequence: current.sequence + 1,
  );
}
