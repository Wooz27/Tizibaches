import 'pothole_status.dart';

class Pothole {
  const Pothole({
    required this.id,
    required this.status,
    required this.severity,
    required this.reportCount,
    required this.latitude,
    required this.longitude,
    required this.address,
    this.firstReportedAt,
    this.lastReportedAt,
    this.fixedAt,
    this.photoUrl,
  });

  final int id;
  final PotholeStatus status;
  final int severity;
  final int reportCount;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime? firstReportedAt;
  final DateTime? lastReportedAt;
  final DateTime? fixedAt;
  final String? photoUrl;

  String get displayAddress =>
      address.trim().isEmpty ? 'Tizimín, Yucatán' : address.trim();

  String get severityLabel => switch (severity) {
    <= 1 => 'Leve',
    2 => 'Moderado',
    3 => 'Grave',
    _ => 'Muy grave',
  };

  Pothole copyWith({
    PotholeStatus? status,
    int? severity,
    int? reportCount,
    String? address,
    DateTime? lastReportedAt,
    DateTime? fixedAt,
    String? photoUrl,
  }) {
    return Pothole(
      id: id,
      status: status ?? this.status,
      severity: severity ?? this.severity,
      reportCount: reportCount ?? this.reportCount,
      latitude: latitude,
      longitude: longitude,
      address: address ?? this.address,
      firstReportedAt: firstReportedAt,
      lastReportedAt: lastReportedAt ?? this.lastReportedAt,
      fixedAt: fixedAt ?? this.fixedAt,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}
