/// User preferences for notification capture (stored natively so the listener can read them).
class CaptureConfig {
  const CaptureConfig({
    required this.enabled,
    required this.allowedPackages,
  });

  final bool enabled;
  final Set<String> allowedPackages;

  CaptureConfig copyWith({bool? enabled, Set<String>? allowedPackages}) {
    return CaptureConfig(
      enabled: enabled ?? this.enabled,
      allowedPackages: allowedPackages ?? this.allowedPackages,
    );
  }
}
