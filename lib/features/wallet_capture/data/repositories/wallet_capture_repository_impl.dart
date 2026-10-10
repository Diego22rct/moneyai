import 'dart:async';
import 'package:moneyai/features/wallet_capture/data/datasources/wallet_capture_local_datasource.dart';
import 'package:moneyai/features/wallet_capture/data/parsers/wallet_parser_registry.dart';
import 'package:moneyai/features/wallet_capture/data/services/notification_capture_service.dart';
import 'package:moneyai/features/wallet_capture/domain/entities/capture_config.dart';
import 'package:moneyai/features/wallet_capture/domain/entities/wallet_capture.dart';
import 'package:moneyai/features/wallet_capture/domain/repositories/wallet_capture_repository.dart';

class WalletCaptureRepositoryImpl implements WalletCaptureRepository {
  WalletCaptureRepositoryImpl({
    required NotificationCaptureService service,
    required WalletCaptureLocalDataSource localDataSource,
    required WalletParserRegistry registry,
  })  : _service = service,
        _localDataSource = localDataSource,
        _registry = registry;

  final NotificationCaptureService _service;
  final WalletCaptureLocalDataSource _localDataSource;
  final WalletParserRegistry _registry;

  @override
  bool get isSupported => _service.isAndroid;

  @override
  Stream<void> get deviceEvents => _service.eventStream;

  @override
  Future<int> syncFromDevice() async {
    final raws = await _service.fetchPending(limit: 100);
    if (raws.isEmpty) return 0;

    int added = 0;
    final now = DateTime.now().toUtc();

    for (final raw in raws) {
      final parsed = _registry.parse(raw);
      if (parsed != null) {
        final capture = WalletCapture(
          origin: raw.origin,
          source: parsed.source,
          dedupeKey: raw.dedupeKey,
          rawTitle: raw.title,
          rawText: raw.text,
          amount: parsed.amount,
          currency: parsed.currency,
          type: parsed.type,
          merchant: parsed.merchant,
          postedAt: raw.postedAt,
          createdAt: now,
        );

        final inserted = await _localDataSource.insertIfAbsent(capture);
        if (inserted) {
          added++;
        }
      }
    }

    // Acknowledge all fetched signals so native queue doesn't grow
    await _service.acknowledge(raws.map((r) => r.nativeId).toList());
    return added;
  }

  @override
  Future<List<WalletCapture>> listPending() {
    return _localDataSource.listPending();
  }

  @override
  Future<void> markConfirmed(int captureId, int expenseId) {
    return _localDataSource.markConfirmed(captureId, expenseId);
  }

  @override
  Future<void> dismiss(int captureId) {
    return _localDataSource.dismiss(captureId);
  }

  @override
  Future<bool> isAccessGranted() {
    return _service.isAccessGranted();
  }

  @override
  Future<void> openAccessSettings() {
    return _service.openAccessSettings();
  }

  @override
  Future<void> openAppDetails() {
    return _service.openAppDetails();
  }

  @override
  Future<CaptureConfig> getConfig() {
    return _service.getConfig();
  }

  @override
  Future<void> updateConfig(CaptureConfig config) {
    return _service.configure(config);
  }
}
