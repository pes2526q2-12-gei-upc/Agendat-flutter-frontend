/// Cache + request deduplication layer (TanStack Query style).
///
/// Responsibilities:
/// - Serve cached data while it is fresh (within [staleTime]).
/// - Deduplicate concurrent requests for the same [key].
/// - Allow forced refresh, invalidation, and optimistic updates.
class QueryClient {
  static final QueryClient instance = QueryClient._();
  QueryClient._();

  final Map<String, _CacheEntry> _cache = {};
  final Map<String, Future<Object?>> _inFlight = {};

  /// Fetches data with caching. Returns cached data if not stale.
  /// Deduplicates concurrent requests to the same [key].
  ///
  /// When [forceRefresh] is true, any cached value is ignored and a brand-new
  /// fetch is started (it does not piggy-back on a pre-existing in-flight
  /// request, so callers truly get fresh data).
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

      final inFlight = _inFlight[key];
      if (inFlight != null) {
        return await inFlight as T;
      }
    }

    final future = queryFn();
    _inFlight[key] = future;

    try {
      final data = await future;
      _cache[key] = _CacheEntry(data: data, fetchedAt: DateTime.now());
      return data;
    } finally {
      if (identical(_inFlight[key], future)) {
        _inFlight.remove(key);
      }
    }
  }

  /// Forces a refetch for [key]. Equivalent to `query(..., forceRefresh: true)`.
  Future<T> refetch<T>({
    required String key,
    required Future<T> Function() queryFn,
    Duration staleTime = const Duration(minutes: 5),
  }) {
    return query<T>(
      key: key,
      queryFn: queryFn,
      staleTime: staleTime,
      forceRefresh: true,
    );
  }

  /// Writes [data] into the cache under [key] without hitting the network.
  /// Useful for optimistic updates after a successful mutation.
  void setQueryData<T>(String key, T data) {
    _cache[key] = _CacheEntry(data: data, fetchedAt: DateTime.now());
  }

  /// Returns cached data for [key], or `null` if missing.
  T? getQueryData<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    return entry.data as T;
  }

  void invalidate(String key) => _cache.remove(key);

  void invalidatePrefix(String prefix) {
    _cache.removeWhere((key, _) => key.startsWith(prefix));
  }

  void invalidateAll() => _cache.clear();
}

class _CacheEntry {
  final Object? data;
  final DateTime fetchedAt;

  _CacheEntry({required this.data, required this.fetchedAt});

  bool isStale(Duration staleTime) =>
      DateTime.now().difference(fetchedAt) > staleTime;
}
