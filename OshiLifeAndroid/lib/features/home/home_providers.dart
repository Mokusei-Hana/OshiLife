import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:oshilife/app/providers.dart';
import 'package:oshilife/data/models/live_event.dart';
import 'package:oshilife/features/home/status_filter.dart';

/// Reactive event list (plan §6.2: drift stream instead of the iOS manual
/// reload-on-lifecycle). The store applies the two-block sort at emission.
final liveEventsProvider = StreamProvider<List<LiveEvent>>(
  (ref) => ref.watch(liveStoreProvider).watchAll(),
);

final statusFilterProvider = StateProvider<StatusFilter>(
  (ref) => StatusFilter.all,
);

/// Shared 60-second ticker replacing the two iOS `TimelineView` clocks.
/// Emits immediately so countdowns render on first frame.
final clockProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream<DateTime>.periodic(
    const Duration(seconds: 60),
    (_) => DateTime.now(),
  );
});
