import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oshilife/features/import/import_providers.dart';
import 'package:oshilife/features/import/share_intent_service.dart';

/// Hooks the share MethodChannel into the app: consumes the buffered
/// cold-start share once the first frame is up (so the router can
/// navigate) and forwards warm-start shares to the coordinator — the
/// standard initial-intent pattern from plan §7.2.
class ShareIntentBootstrap extends ConsumerStatefulWidget {
  const ShareIntentBootstrap({super.key, this.service, required this.child});

  final ShareIntentService? service;
  final Widget child;

  @override
  ConsumerState<ShareIntentBootstrap> createState() =>
      _ShareIntentBootstrapState();
}

class _ShareIntentBootstrapState extends ConsumerState<ShareIntentBootstrap> {
  late final ShareIntentService _service =
      widget.service ?? ShareIntentService();

  @override
  void initState() {
    super.initState();
    _service.listen(_handle);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final initial = await _service.consumeInitialShare();
      if (initial != null && mounted) _handle(initial);
    });
  }

  void _handle(SharedPayload payload) {
    // The coordinator drives navigation and error state itself.
    ref.read(shareReceiveCoordinatorProvider).handleSharedPayload(payload);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
