import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:oshilife/core/design/widgets/empty_state.dart';
import 'package:oshilife/data/db/live_queries.dart';
import 'package:oshilife/data/images/image_store.dart';
import 'package:oshilife/data/models/live_event.dart';
import 'package:oshilife/features/home/event_carousel_card.dart';
import 'package:oshilife/l10n/app_localizations.dart';

/// Port of `HomeDashboardView.swift`: the card home. An upcoming hero
/// carousel with center-peek paging, scale/fade transitions, auto-hiding
/// page dots, and an attended-history shelf. The 60 s clock comes in as a
/// plain prop, exactly like the iOS `TimelineView` design.
class DashboardView extends StatefulWidget {
  const DashboardView({
    super.key,
    required this.events,
    required this.now,
    this.imageStore,
    this.onOpen,
    this.onEdit,
  });

  final List<LiveEvent> events;
  final DateTime now;
  final ImageStore? imageStore;
  final void Function(LiveEvent event)? onOpen;
  final void Function(LiveEvent event)? onEdit;

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  PageController? _controller;
  double _viewportFraction = 1;
  double _page = 0;
  bool _showsIndicator = false;
  Timer? _indicatorDismissTimer;

  @override
  void dispose() {
    _indicatorDismissTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  PageController _controllerFor(double viewportFraction) {
    var controller = _controller;
    if (controller == null || _viewportFraction != viewportFraction) {
      controller?.dispose();
      controller = PageController(viewportFraction: viewportFraction);
      controller.addListener(() {
        setState(() => _page = controller!.page ?? 0);
      });
      _controller = controller;
      _viewportFraction = viewportFraction;
      _page = 0;
    }
    return controller;
  }

  void _handleScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification) {
      _indicatorDismissTimer?.cancel();
      if (!_showsIndicator) setState(() => _showsIndicator = true);
    } else if (notification is ScrollEndNotification) {
      // iOS hides the dots 700 ms after the scroll settles.
      _indicatorDismissTimer?.cancel();
      _indicatorDismissTimer = Timer(const Duration(milliseconds: 700), () {
        if (mounted) setState(() => _showsIndicator = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final upcoming = upcomingEvents(widget.events, now: widget.now);
    final attended = historicalEvents(widget.events);

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            l10n.homeUpcoming,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (upcoming.isEmpty)
          SizedBox(
            height: 180,
            child: EmptyState(
              icon: Icons.event_available_outlined,
              title: l10n.homeNoUpcoming,
            ),
          )
        else
          _carousel(upcoming),
        if (attended.isNotEmpty) ...[
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              l10n.homeAttended,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 208,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: attended.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final event = attended[index];
                return HistoricalEventCard(
                  event: event,
                  imageStore: widget.imageStore,
                  onOpen: () => widget.onOpen?.call(event),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _carousel(List<LiveEvent> upcoming) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // iOS: cardWidth = min(360, max(288, width - 32)), centered peek.
        final width = constraints.maxWidth;
        final cardWidth = math.min(360.0, math.max(288.0, width - 32));
        final viewportFraction = math.min(1.0, cardWidth / width);
        final controller = _controllerFor(viewportFraction);

        return Column(
          children: [
            SizedBox(
              height: 560,
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  _handleScrollNotification(notification);
                  return false;
                },
                child: PageView.builder(
                  controller: controller,
                  padEnds: true,
                  clipBehavior: Clip.none,
                  itemCount: upcoming.length,
                  itemBuilder: (context, index) {
                    final event = upcoming[index];
                    final delta = (_page - index).abs().clamp(0.0, 1.0);
                    // iOS scrollTransition: scale 1 → 0.85, opacity 1 → 0.62.
                    final scale = 1 - 0.15 * delta;
                    final opacity = 1 - 0.38 * delta;
                    return Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: SingleChildScrollView(
                              physics: const NeverScrollableScrollPhysics(),
                              child: EventCarouselCard(
                                event: event,
                                now: widget.now,
                                imageStore: widget.imageStore,
                                onOpen: () => widget.onOpen?.call(event),
                                onEdit: widget.onEdit == null
                                    ? null
                                    : () => widget.onEdit!.call(event),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(
              height: 20,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 180),
                opacity: _showsIndicator && upcoming.length > 1 ? 1 : 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var index = 0; index < upcoming.length; index += 1)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              (_page.round() == index
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant)
                                  .withValues(
                                    alpha: _page.round() == index ? 0.9 : 0.35,
                                  ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
