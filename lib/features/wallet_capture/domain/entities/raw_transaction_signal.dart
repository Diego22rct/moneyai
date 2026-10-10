/// Where a raw transaction signal came from.
///
/// Today only Android notifications exist; iOS Shortcuts (App Intent) or email
/// alerts can be added as new origins feeding the same pipeline.
enum SignalOrigin {
  androidNotification('android_notification'),
  iosShortcut('ios_shortcut'),
  email('email');

  const SignalOrigin(this.id);

  final String id;

  static SignalOrigin fromId(String id) {
    return values.firstWhere(
      (origin) => origin.id == id,
      orElse: () => androidNotification,
    );
  }
}

/// Unparsed text describing a possible financial movement, as received from the device.
class RawTransactionSignal {
  const RawTransactionSignal({
    required this.nativeId,
    required this.origin,
    required this.packageName,
    required this.title,
    required this.text,
    required this.postedAt,
    required this.dedupeKey,
    this.subText,
  });

  /// Row id in the native queue, used to acknowledge it.
  final int nativeId;
  final SignalOrigin origin;
  final String packageName;
  final String title;
  final String text;
  final String? subText;
  final DateTime postedAt;
  final String dedupeKey;

  /// Title + text (+ subtext) joined for parsing.
  String get fullText {
    return <String>[title, text, subText ?? '']
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .join('\n');
  }

  factory RawTransactionSignal.fromPlatformMap(Map<Object?, Object?> map) {
    final int nativeId = (map['id'] as num).toInt();
    final int postedAtMs = (map['postedAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;

    return RawTransactionSignal(
      nativeId: nativeId,
      origin: SignalOrigin.androidNotification,
      packageName: (map['packageName'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      text: (map['text'] as String?) ?? '',
      subText: map['subText'] as String?,
      postedAt: DateTime.fromMillisecondsSinceEpoch(postedAtMs, isUtc: true),
      dedupeKey: (map['dedupeKey'] as String?) ?? 'native-$nativeId',
    );
  }
}
