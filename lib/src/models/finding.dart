/// Severity assigned to a compatibility finding.
enum Severity {
  /// Analysis could not continue or a required project file is missing.
  blocker,

  /// A likely build or migration failure.
  high,

  /// A significant risk or missing detail that deserves attention.
  medium,

  /// Informational context useful during restoration planning.
  info;

  /// Uppercase label used in text and JSON reports.
  String get label => switch (this) {
    Severity.blocker => 'BLOCKER',
    Severity.high => 'HIGH',
    Severity.medium => 'MEDIUM',
    Severity.info => 'INFO',
  };
}

/// A single issue, risk, or note produced by a compatibility rule.
class Finding {
  /// Creates a rule finding.
  const Finding({
    required this.id,
    required this.severity,
    required this.title,
    required this.message,
    this.location,
    this.sourceFile,
    this.line,
    this.detectedValue,
    this.recommendation,
  });

  /// Stable identifier for automation and tests.
  final String id;

  /// Impact level for the finding.
  final Severity severity;

  /// Short human-readable summary.
  final String title;

  /// Detailed explanation of the detected problem or context.
  final String message;

  /// Human-readable source location, usually file plus line.
  final String? location;

  /// Relative source file that triggered the finding.
  final String? sourceFile;

  /// One-based line number inside [sourceFile].
  final int? line;

  /// Raw value detected by the scanner, when useful.
  final String? detectedValue;

  /// Suggested next action for resolving the finding.
  final String? recommendation;

  /// Converts this finding to the JSON report shape.
  Map<String, Object?> toJson() => {
    'id': id,
    'severity': severity.label,
    'title': title,
    'message': message,
    if (location != null) 'location': location,
    if (sourceFile != null) 'sourceFile': sourceFile,
    if (line != null) 'line': line,
    if (detectedValue != null) 'detectedValue': detectedValue,
    if (recommendation != null) 'recommendation': recommendation,
  };
}
