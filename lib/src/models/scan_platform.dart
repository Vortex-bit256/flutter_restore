/// Flutter target platform selected for scan output and rule evaluation.
enum ScanPlatform {
  /// Android target files.
  android,

  /// iOS target files.
  ios,

  /// Linux desktop target files.
  linux,

  /// Windows desktop target files.
  windows,

  /// Web target files.
  web;

  /// Stable CLI and JSON label.
  String get label => name;
}

/// All concrete platforms supported by the scanner.
const allScanPlatforms = {
  ScanPlatform.android,
  ScanPlatform.ios,
  ScanPlatform.linux,
  ScanPlatform.windows,
  ScanPlatform.web,
};

/// Parses a scan platform argument. `all` returns every supported platform.
Set<ScanPlatform>? parseScanPlatforms(String value) {
  final normalized = value.trim().toLowerCase();
  if (normalized == 'all') {
    return allScanPlatforms;
  }
  for (final platform in ScanPlatform.values) {
    if (platform.label == normalized) {
      return {platform};
    }
  }
  return null;
}
