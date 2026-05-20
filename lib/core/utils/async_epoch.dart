/// Incrementa un comptador per ignorar resultats async obsolets en UI.
class AsyncEpoch {
  int _value = 0;

  int get current => _value;

  /// Inicia una nova operació; retorna l'epoch assignat.
  int bump() => ++_value;

  bool isCurrent(int epoch) => epoch == _value;
}
