import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:moneyai/features/expenses/domain/entities/expense.dart';
import 'package:moneyai/features/wallet_capture/data/datasources/wallet_capture_local_datasource.dart';
import 'package:moneyai/features/wallet_capture/data/parsers/wallet_parser_registry.dart';
import 'package:moneyai/features/wallet_capture/data/repositories/wallet_capture_repository_impl.dart';
import 'package:moneyai/features/wallet_capture/data/services/notification_capture_service.dart';
import 'package:moneyai/features/wallet_capture/domain/entities/capture_config.dart';
import 'package:moneyai/features/wallet_capture/domain/entities/raw_transaction_signal.dart';
import 'package:moneyai/features/wallet_capture/domain/entities/wallet_capture.dart';
import 'package:moneyai/features/wallet_capture/domain/entities/wallet_source.dart';

class FakeNotificationCaptureService implements NotificationCaptureService {
  List<RawTransactionSignal> pending = <RawTransactionSignal>[];
  List<int> acknowledged = <int>[];
  bool accessGranted = true;

  @override
  bool get isAndroid => true;

  @override
  Stream<void> get eventStream => const Stream<void>.empty();

  @override
  Future<List<RawTransactionSignal>> fetchPending({int limit = 100}) async => pending;

  @override
  Future<void> acknowledge(List<int> ids) async {
    acknowledged.addAll(ids);
  }

  @override
  Future<bool> isAccessGranted() async => accessGranted;

  @override
  Future<void> openAccessSettings() async {}

  @override
  Future<void> openAppDetails() async {}

  @override
  Future<CaptureConfig> getConfig() async => const CaptureConfig(
        enabled: true,
        allowedPackages: <String>{'com.google.android.apps.walletnfcrel'},
      );

  @override
  Future<void> configure(CaptureConfig config) async {}
}

class FakeWalletCaptureLocalDataSource implements WalletCaptureLocalDataSource {
  final List<WalletCapture> stored = <WalletCapture>[];
  final List<int> confirmedIds = <int>[];
  final List<int> dismissedIds = <int>[];

  @override
  Future<bool> insertIfAbsent(WalletCapture capture) async {
    if (stored.any((c) => c.dedupeKey == capture.dedupeKey)) {
      return false;
    }
    stored.add(capture);
    return true;
  }

  @override
  Future<List<WalletCapture>> listPending() async {
    return stored.where((c) => c.status == WalletCaptureStatus.pending).toList();
  }

  @override
  Future<void> markConfirmed(int id, int expenseId) async {
    confirmedIds.add(id);
    final idx = stored.indexWhere((c) => c.id == id);
    if (idx != -1) {
      stored[idx] = stored[idx].copyWith(
        status: WalletCaptureStatus.confirmed,
        expenseId: expenseId,
      );
    }
  }

  @override
  Future<void> dismiss(int id) async {
    dismissedIds.add(id);
    final idx = stored.indexWhere((c) => c.id == id);
    if (idx != -1) {
      stored[idx] = stored[idx].copyWith(
        status: WalletCaptureStatus.dismissed,
      );
    }
  }
}

void main() {
  late FakeNotificationCaptureService fakeService;
  late FakeWalletCaptureLocalDataSource fakeLocal;
  late WalletParserRegistry registry;
  late WalletCaptureRepositoryImpl repository;

  setUp(() {
    fakeService = FakeNotificationCaptureService();
    fakeLocal = FakeWalletCaptureLocalDataSource();
    registry = WalletParserRegistry();
    repository = WalletCaptureRepositoryImpl(
      service: fakeService,
      localDataSource: fakeLocal,
      registry: registry,
    );
  });

  group('WalletCaptureRepositoryImpl', () {
    test('syncFromDevice drains queue, parses payments and acknowledges all signals', () async {
      fakeService.pending = <RawTransactionSignal>[
        RawTransactionSignal(
          nativeId: 101,
          origin: SignalOrigin.androidNotification,
          packageName: 'com.google.android.apps.walletnfcrel',
          title: 'Tambo',
          text: 'S/ 12.50 con Visa •••• 1234',
          postedAt: DateTime.parse('2026-03-24T10:00:00Z'),
          dedupeKey: 'hash-1',
        ),
        // Non-transaction notification (should be acknowledged but not saved)
        RawTransactionSignal(
          nativeId: 102,
          origin: SignalOrigin.androidNotification,
          packageName: 'com.google.android.apps.walletnfcrel',
          title: 'Bienvenido',
          text: 'Tu tarjeta está lista',
          postedAt: DateTime.parse('2026-03-24T10:01:00Z'),
          dedupeKey: 'hash-2',
        ),
      ];

      final addedCount = await repository.syncFromDevice();

      expect(addedCount, 1);
      expect(fakeLocal.stored.length, 1);
      expect(fakeLocal.stored.first.amount, 12.50);
      expect(fakeLocal.stored.first.merchant, 'Tambo');
      expect(fakeLocal.stored.first.source, WalletSource.googleWallet);
      expect(fakeLocal.stored.first.type, TransactionType.expense);

      // Both signals acknowledged to keep native queue clean
      expect(fakeService.acknowledged, <int>[101, 102]);
    });

    test('deduplicates signals with same dedupeKey', () async {
      fakeService.pending = <RawTransactionSignal>[
        RawTransactionSignal(
          nativeId: 201,
          origin: SignalOrigin.androidNotification,
          packageName: 'com.google.android.apps.walletnfcrel',
          title: 'OXXO',
          text: 'S/ 20.00 con Visa',
          postedAt: DateTime.parse('2026-03-24T11:00:00Z'),
          dedupeKey: 'duplicate-key',
        ),
      ];

      final firstSync = await repository.syncFromDevice();
      expect(firstSync, 1);

      // Same key received again
      final secondSync = await repository.syncFromDevice();
      expect(secondSync, 0);
      expect(fakeLocal.stored.length, 1);
    });
  });
}
