import 'package:flutter_test/flutter_test.dart';
import 'package:crayoli_closet/core/utils/bounded_concurrency.dart';

void main() {
  group('mapWithConcurrency', () {
    test('preserves input order regardless of completion order', () async {
      // Larger delays finish later even though they start first, so a
      // completion-ordered result would come back as [5, 10, 20, 30].
      const delays = [30, 10, 20, 5];
      final results = await mapWithConcurrency<int, int>(
        delays,
        (d) => Future.delayed(Duration(milliseconds: d), () => d),
        maxConcurrent: 4,
      );
      expect(results, delays);
    });

    test('never runs more than maxConcurrent actions at once', () async {
      var current = 0;
      var peak = 0;
      final items = List.generate(10, (i) => i);

      await mapWithConcurrency<int, int>(
        items,
        (i) async {
          current++;
          if (current > peak) peak = current;
          await Future.delayed(const Duration(milliseconds: 5));
          current--;
          return i;
        },
        maxConcurrent: 3,
      );

      expect(peak, lessThanOrEqualTo(3));
    });

    test('processes every item exactly once', () async {
      final items = List.generate(9, (i) => i);
      final seen = <int>[];

      final results = await mapWithConcurrency<int, int>(
        items,
        (i) async {
          seen.add(i);
          return i * 2;
        },
        maxConcurrent: 4,
      );

      seen.sort();
      expect(seen, items);
      expect(results, items.map((i) => i * 2).toList());
    });

    test('returns an empty list for empty input without calling action', () async {
      var calls = 0;
      final results = await mapWithConcurrency<int, int>(
        const [],
        (i) async {
          calls++;
          return i;
        },
        maxConcurrent: 3,
      );
      expect(results, isEmpty);
      expect(calls, 0);
    });

    test('works when maxConcurrent exceeds the item count', () async {
      final results = await mapWithConcurrency<int, int>(
        [1, 2],
        (i) async => i,
        maxConcurrent: 10,
      );
      expect(results, [1, 2]);
    });

    test('propagates a failure from action', () async {
      expect(
        () => mapWithConcurrency<int, int>(
          [1, 2, 3],
          (i) async {
            if (i == 2) throw StateError('boom');
            return i;
          },
          maxConcurrent: 2,
        ),
        throwsStateError,
      );
    });
  });
}
