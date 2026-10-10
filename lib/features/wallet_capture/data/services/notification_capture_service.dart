import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:moneyai/features/wallet_capture/domain/entities/capture_config.dart';
import 'package:moneyai/features/wallet_capture/domain/entities/raw_transaction_signal.dart';
import 'package:moneyai/features/wallet_capture/domain/entities/wallet_source.dart';

/// Wraps native Android notification capture channels.
/// Safe to instantiate on any platform; methods return default/no-op on non-Android.
class NotificationCaptureService {
  NotificationCaptureService({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
  })  : _methodChannel = methodChannel ?? const MethodChannel('moneyai/notification_capture'),
        _eventChannel = eventChannel ?? const EventChannel('moneyai/notification_capture/events');

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;

  bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Stream<void> get eventStream {
    if (!isAndroid) {
      return const Stream<void>.empty();
    }
    return _eventChannel.receiveBroadcastStream().map((_) {});
  }

  Future<bool> isAccessGranted() async {
    if (!isAndroid) return false;
    try {
      final res = await _methodChannel.invokeMethod<bool>('isAccessGranted');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<void> openAccessSettings() async {
    if (!isAndroid) return;
    try {
      await _methodChannel.invokeMethod<void>('openAccessSettings');
    } catch (_) {}
  }

  Future<void> openAppDetails() async {
    if (!isAndroid) return;
    try {
      await _methodChannel.invokeMethod<void>('openAppDetails');
    } catch (_) {}
  }

  Future<List<RawTransactionSignal>> fetchPending({int limit = 100}) async {
    if (!isAndroid) return <RawTransactionSignal>[];
    try {
      final res = await _methodChannel.invokeListMethod<Map<Object?, Object?>>(
        'fetchPending',
        <String, Object?>{'limit': limit},
      );
      if (res == null) return <RawTransactionSignal>[];
      return res.map(RawTransactionSignal.fromPlatformMap).toList();
    } catch (_) {
      return <RawTransactionSignal>[];
    }
  }

  Future<void> acknowledge(List<int> ids) async {
    if (!isAndroid || ids.isEmpty) return;
    try {
      await _methodChannel.invokeMethod<void>('acknowledge', <String, Object?>{
        'ids': ids,
      });
    } catch (_) {}
  }

  Future<CaptureConfig> getConfig() async {
    if (!isAndroid) {
      return CaptureConfig(
        enabled: false,
        allowedPackages: WalletSource.supported.expand((s) => s.packageNames).toSet(),
      );
    }
    try {
      final res = await _methodChannel.invokeMapMethod<String, Object?>('getConfig');
      final bool enabled = (res?['enabled'] as bool?) ?? true;
      final List<Object?> rawPkgs = (res?['packages'] as List<Object?>?) ?? <Object?>[];
      final Set<String> packages = rawPkgs.whereType<String>().toSet();

      return CaptureConfig(
        enabled: enabled,
        allowedPackages: packages.isNotEmpty
            ? packages
            : WalletSource.supported.expand((s) => s.packageNames).toSet(),
      );
    } catch (_) {
      return CaptureConfig(
        enabled: true,
        allowedPackages: WalletSource.supported.expand((s) => s.packageNames).toSet(),
      );
    }
  }

  Future<void> configure(CaptureConfig config) async {
    if (!isAndroid) return;
    try {
      await _methodChannel.invokeMethod<void>('configure', <String, Object?>{
        'enabled': config.enabled,
        'packages': config.allowedPackages.toList(),
      });
    } catch (_) {}
  }
}
