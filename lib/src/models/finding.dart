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
  });

  final String id;
  final Severity severity;
  final String title;
  final String message;
  final String? location;

  Map<String, Object?> toJson() => {
    'id': id,
    'severity': severity.label,
    'title': title,
    'message': message,
    if (location != null) 'location': location,
  };
}
