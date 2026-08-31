enum Severity {
  blocker,
  high,
  medium,
  info;

  String get label => switch (this) {
    Severity.blocker => 'BLOCKER',
    Severity.high => 'HIGH',
    Severity.medium => 'MEDIUM',
    Severity.info => 'INFO',
  };
}

class Finding {
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

  final String id;
  final Severity severity;
  final String title;
  final String message;
  final String? location;
  final String? sourceFile;
  final int? line;
  final String? detectedValue;
  final String? recommendation;

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
