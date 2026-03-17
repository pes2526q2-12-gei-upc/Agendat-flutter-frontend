class QueryClient {
  static final QueryClient instance = QueryClient._();
  QueryClient._();

  final Map<String, _CacheEntry> _cache = {};
  final Map<String, Future<dynamic>> _inFlight = {};

  /// Fetches data with caching. Returns cached data if not stale.
  /// Deduplicates concurrent requests to the same key.
  Future<T> query<T>({
    required String key,
    required Future<T> Function() queryFn,
    Duration staleTime = const Duration(minutes: 5),
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final entry = _cache[key];
      if (entry != null && !entry.isStale(staleTime)) {
        return entry.data as T;
      }
    }

    if (_inFlight.containsKey(key)) {
      return await _inFlight[key] as T;
    }

    final future = queryFn();
    _inFlight[key] = future;

    try {
      final data = await future;
      _cache[key] = _CacheEntry(data: data, fetchedAt: DateTime.now());
      return data;
    } finally {
      _inFlight.remove(key);
    }
  }

  void invalidate(String key) => _cache.remove(key);

  void invalidatePrefix(String prefix) {
    _cache.removeWhere((key, _) => key.startsWith(prefix));
  }

  void invalidateAll() => _cache.clear();
}

class _CacheEntry {
  final dynamic data;
  final DateTime fetchedAt;

  _CacheEntry({required this.data, required this.fetchedAt});

  bool isStale(Duration staleTime) =>
      DateTime.now().difference(fetchedAt) > staleTime;
}
