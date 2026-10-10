/// Wallet/bank apps whose notifications can be captured.
///
/// Add new sources (Yape, Plin, BCP...) here together with a parser in
/// `data/parsers/` and register it in `WalletParserRegistry`.
enum WalletSource {
  googleWallet(
    id: 'google_wallet',
    displayName: 'Google Wallet',
    packageNames: <String>['com.google.android.apps.walletnfcrel'],
  ),
  googlePay(
    id: 'google_pay',
    displayName: 'Google Pay',
    packageNames: <String>['com.google.android.apps.nbu.paisa.user'],
  ),
  unknown(
    id: 'unknown',
    displayName: 'Billetera',
    packageNames: <String>[],
  );

  const WalletSource({
    required this.id,
    required this.displayName,
    required this.packageNames,
  });

  final String id;
  final String displayName;
  final List<String> packageNames;

  /// Sources the user can enable today.
  static const List<WalletSource> supported = <WalletSource>[googleWallet, googlePay];

  static WalletSource fromPackage(String packageName) {
    return values.firstWhere(
      (source) => source.packageNames.contains(packageName),
      orElse: () => unknown,
    );
  }

  static WalletSource fromId(String id) {
    return values.firstWhere(
      (source) => source.id == id,
      orElse: () => unknown,
    );
  }
}
