import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moneyai/features/expenses/presentation/providers/expense_list_provider.dart';
import 'package:moneyai/features/wallet_capture/data/datasources/wallet_capture_local_datasource.dart';
import 'package:moneyai/features/wallet_capture/data/parsers/wallet_parser_registry.dart';
import 'package:moneyai/features/wallet_capture/data/repositories/wallet_capture_repository_impl.dart';
import 'package:moneyai/features/wallet_capture/data/services/notification_capture_service.dart';
import 'package:moneyai/features/wallet_capture/domain/entities/capture_config.dart';
import 'package:moneyai/features/wallet_capture/domain/entities/wallet_capture.dart';
import 'package:moneyai/features/wallet_capture/domain/repositories/wallet_capture_repository.dart';

final notificationCaptureServiceProvider = Provider<NotificationCaptureService>((ref) {
  return NotificationCaptureService();
});

final walletCaptureLocalDataSourceProvider = Provider<WalletCaptureLocalDataSource>((ref) {
  return WalletCaptureLocalDataSource(ref.watch(sqliteServiceProvider));
});

final walletParserRegistryProvider = Provider<WalletParserRegistry>((ref) {
  return WalletParserRegistry();
});

final walletCaptureRepositoryProvider = Provider<WalletCaptureRepository>((ref) {
  return WalletCaptureRepositoryImpl(
    service: ref.watch(notificationCaptureServiceProvider),
    localDataSource: ref.watch(walletCaptureLocalDataSourceProvider),
    registry: ref.watch(walletParserRegistryProvider),
  );
});

/// Whether Android Notification Listener permission is currently granted to MoneyAI.
final notificationAccessProvider = FutureProvider.autoDispose<bool>((ref) async {
  final repo = ref.watch(walletCaptureRepositoryProvider);
  return repo.isAccessGranted();
});

/// Manages capture configuration (enabled & selected wallet apps).
final captureConfigProvider =
    AsyncNotifierProvider<CaptureConfigNotifier, CaptureConfig>(
  CaptureConfigNotifier.new,
);

class CaptureConfigNotifier extends AsyncNotifier<CaptureConfig> {
  @override
  Future<CaptureConfig> build() {
    return ref.read(walletCaptureRepositoryProvider).getConfig();
  }

  Future<void> setEnabled(bool enabled) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final updated = current.copyWith(enabled: enabled);
    state = AsyncData(updated);
    await ref.read(walletCaptureRepositoryProvider).updateConfig(updated);
  }

  Future<void> togglePackage(String packageName) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final set = Set<String>.from(current.allowedPackages);
    if (set.contains(packageName)) {
      set.remove(packageName);
    } else {
      set.add(packageName);
    }
    final updated = current.copyWith(allowedPackages: set);
    state = AsyncData(updated);
    await ref.read(walletCaptureRepositoryProvider).updateConfig(updated);
  }
}

/// Manages list of pending captures from wallet notifications.
final walletInboxProvider =
    AsyncNotifierProvider<WalletInboxNotifier, List<WalletCapture>>(
  WalletInboxNotifier.new,
);

class WalletInboxNotifier extends AsyncNotifier<List<WalletCapture>> {
  StreamSubscription<void>? _eventSub;

  @override
  Future<List<WalletCapture>> build() async {
    final repo = ref.read(walletCaptureRepositoryProvider);

    // Cancel prior subscription if any
    _eventSub?.cancel();
    _eventSub = repo.deviceEvents.listen((_) {
      syncAndRefresh();
    });

    ref.onDispose(() {
      _eventSub?.cancel();
    });

    // Sync incoming signals from device on build
    await repo.syncFromDevice();
    return repo.listPending();
  }

  Future<void> syncAndRefresh() async {
    final repo = ref.read(walletCaptureRepositoryProvider);
    await repo.syncFromDevice();
    state = AsyncData(await repo.listPending());
  }

  Future<void> dismiss(int captureId) async {
    final repo = ref.read(walletCaptureRepositoryProvider);
    await repo.dismiss(captureId);
    state = AsyncData(await repo.listPending());
  }

  Future<void> markConfirmed(int captureId, int expenseId) async {
    final repo = ref.read(walletCaptureRepositoryProvider);
    await repo.markConfirmed(captureId, expenseId);
    state = AsyncData(await repo.listPending());
  }
}

/// Number of pending captures waiting in the inbox (for notification badge).
final pendingCaptureCountProvider = Provider<int>((ref) {
  return ref.watch(walletInboxProvider).maybeWhen(
        data: (captures) => captures.length,
        orElse: () => 0,
      );
});
