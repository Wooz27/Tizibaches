import 'dart:typed_data';

import 'pothole_status.dart';

class Report {
  const Report({
    required this.id,
    required this.potholeId,
    required this.status,
    required this.severity,
    required this.description,
    required this.createdAt,
    this.photoUrl,
  });

  final int id;
  final int potholeId;
  final PotholeStatus status;
  final int severity;
  final String description;
  final DateTime createdAt;
  final String? photoUrl;

  String get severityLabel => switch (severity) {
    <= 1 => 'Leve',
    2 => 'Moderado',
    3 => 'Grave',
    _ => 'Muy grave',
  };

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: (json['id'] as num?)?.toInt() ?? 0,
      potholeId: (json['pothole_id'] as num?)?.toInt() ?? 0,
      status: PotholeStatus.fromApi(json['status'] as String?),
      severity: (json['severity'] as num?)?.toInt() ?? 1,
      description: json['description'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      photoUrl: json['photo_url'] as String?,
    );
  }
}

class ReportDraft {
  const ReportDraft({
    required this.latitude,
    required this.longitude,
    required this.severity,
    required this.photoBytes,
    required this.photoName,
    this.description = '',
    this.approximateLocation = false,
  });

  final double latitude;
  final double longitude;
  final int severity;
  final Uint8List photoBytes;
  final String photoName;
  final String description;
  final bool approximateLocation;
}

class ReportSubmission {
  const ReportSubmission({
    required this.report,
    required this.created,
    required this.distanceMeters,
  });

  final Report report;
  final bool created;
  final double? distanceMeters;

  factory ReportSubmission.fromJson(Map<String, dynamic> json) {
    return ReportSubmission(
      report: Report.fromJson(json),
      created: json['created'] as bool? ?? true,
      distanceMeters: (json['distance_m'] as num?)?.toDouble(),
    );
  }
}
