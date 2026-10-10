import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyai/features/wallet_capture/presentation/providers/wallet_capture_providers.dart';

/// Listens for app lifecycle resume events to refresh notification access status
/// and sync any notifications captured while the app was in the background or closed.
class CaptureLifecycleListener extends ConsumerStatefulWidget {
  const CaptureLifecycleListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<CaptureLifecycleListener> createState() =>
      _CaptureLifecycleListenerState();
}

class _CaptureLifecycleListenerState
    extends ConsumerState<CaptureLifecycleListener>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-check notification access in case the user just returned from system settings
      ref.invalidate(notificationAccessProvider);
      // Drain and display any newly captured payments
      ref.read(walletInboxProvider.notifier).syncAndRefresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
