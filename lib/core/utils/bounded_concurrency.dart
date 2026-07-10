/// Maps [items] through [action] with at most [maxConcurrent] operations in
/// flight at once, preserving the original order in the result.
///
/// Unlike `Future.wait(items.map(action))` — which starts every operation
/// at once — concurrency here is bounded by a small worker pool: each of
/// [maxConcurrent] workers repeatedly claims the next unclaimed index and
/// awaits [action] on it. This is safe without locks because Dart is
/// single-threaded and cooperative: a worker only yields control at an
/// `await`, so claiming an index (read + increment of the shared cursor)
/// always completes atomically between yield points.
///
/// Use this when [action] is memory- or resource-heavy (e.g. on-device ML
/// inference, each call holding a decoded image in native memory) and
/// running all of them at once risks exhausting device memory.
Future<List<R>> mapWithConcurrency<T, R>(
  List<T> items,
  Future<R> Function(T item) action, {
  required int maxConcurrent,
}) async {
  if (items.isEmpty) return const [];
  assert(maxConcurrent > 0, 'maxConcurrent must be positive');

  final results = List<R?>.filled(items.length, null);
  var nextIndex = 0;

  Future<void> worker() async {
    while (true) {
      final i = nextIndex;
      if (i >= items.length) return;
      nextIndex++;
      results[i] = await action(items[i]);
    }
  }

  final workerCount =
      maxConcurrent < items.length ? maxConcurrent : items.length;
  await Future.wait(List.generate(workerCount, (_) => worker()));

  return results.cast<R>();
}
