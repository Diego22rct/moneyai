import 'package:moneyai/features/wallet_capture/domain/entities/capture_config.dart';
import 'package:moneyai/features/wallet_capture/domain/entities/wallet_capture.dart';

/// Single source of truth for movements detected from wallet notifications.
abstract class WalletCaptureRepository {
  /// Whether automatic capture is available on this platform (Android only today).
  bool get isSupported;

  /// Emits whenever the device queued a new raw notification (app running).
  Stream<void> get deviceEvents;

  /// Drains the device queue, parses it and stores new pending captures.
  /// Returns how many new captures were added.
  Future<int> syncFromDevice();

  Future<List<WalletCapture>> listPending();

  Future<void> markConfirmed(int captureId, int expenseId);

  Future<void> dismiss(int captureId);

  Future<bool> isAccessGranted();

  Future<void> openAccessSettings();

  Future<void> openAppDetails();

  Future<CaptureConfig> getConfig();

  Future<void> updateConfig(CaptureConfig config);
}
