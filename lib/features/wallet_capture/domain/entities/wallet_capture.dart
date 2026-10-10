import 'package:moneyai/features/expenses/domain/entities/expense.dart';
import 'package:moneyai/features/wallet_capture/domain/entities/raw_transaction_signal.dart';
import 'package:moneyai/features/wallet_capture/domain/entities/wallet_source.dart';

enum WalletCaptureStatus { pending, confirmed, dismissed }

/// A movement detected from a wallet notification, stored locally until reviewed.
class WalletCapture {
  const WalletCapture({
    this.id,
    required this.origin,
    required this.source,
    required this.dedupeKey,
    this.rawTitle,
    this.rawText,
    required this.amount,
    required this.currency,
    required this.type,
    this.merchant,
    required this.postedAt,
    this.status = WalletCaptureStatus.pending,
    this.expenseId,
    required this.createdAt,
  });

  final int? id;
  final SignalOrigin origin;
  final WalletSource source;
  final String dedupeKey;

  /// Raw notification text. Kept only while pending; wiped once resolved.
  final String? rawTitle;
  final String? rawText;

  final double amount;
  final String currency;
  final TransactionType type;
  final String? merchant;
  final DateTime postedAt;
  final WalletCaptureStatus status;
  final int? expenseId;
  final DateTime createdAt;

  /// Human readable label for lists and drafts.
  String get displayTitle {
    final String? cleanedMerchant = merchant?.trim();
    if (cleanedMerchant != null && cleanedMerchant.isNotEmpty) {
      return cleanedMerchant;
    }
    final String? cleanedTitle = rawTitle?.trim();
    if (cleanedTitle != null && cleanedTitle.isNotEmpty) {
      return cleanedTitle;
    }
    return source.displayName;
  }

  WalletCapture copyWith({
    int? id,
    WalletCaptureStatus? status,
    int? expenseId,
  }) {
    return WalletCapture(
      id: id ?? this.id,
      origin: origin,
      source: source,
      dedupeKey: dedupeKey,
      rawTitle: rawTitle,
      rawText: rawText,
      amount: amount,
      currency: currency,
      type: type,
      merchant: merchant,
      postedAt: postedAt,
      status: status ?? this.status,
      expenseId: expenseId ?? this.expenseId,
      createdAt: createdAt,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'id': id,
      'origin': origin.id,
      'source': source.id,
      'dedupe_key': dedupeKey,
      'raw_title': rawTitle,
      'raw_text': rawText,
      'amount': amount,
      'currency': currency,
      'type': type.name,
      'merchant': merchant,
      'posted_at': postedAt.toUtc().toIso8601String(),
      'status': status.name,
      'expense_id': expenseId,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }

  factory WalletCapture.fromMap(Map<String, Object?> map) {
    final String typeValue = (map['type'] as String?) ?? TransactionType.expense.name;
    final String statusValue = (map['status'] as String?) ?? WalletCaptureStatus.pending.name;

    return WalletCapture(
      id: map['id'] as int?,
      origin: SignalOrigin.fromId((map['origin'] as String?) ?? ''),
      source: WalletSource.fromId((map['source'] as String?) ?? ''),
      dedupeKey: map['dedupe_key'] as String,
      rawTitle: map['raw_title'] as String?,
      rawText: map['raw_text'] as String?,
      amount: (map['amount'] as num).toDouble(),
      currency: map['currency'] as String,
      type: TransactionType.values.firstWhere(
        (value) => value.name == typeValue,
        orElse: () => TransactionType.expense,
      ),
      merchant: map['merchant'] as String?,
      postedAt: DateTime.parse(map['posted_at'] as String),
      status: WalletCaptureStatus.values.firstWhere(
        (value) => value.name == statusValue,
        orElse: () => WalletCaptureStatus.pending,
      ),
      expenseId: map['expense_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
