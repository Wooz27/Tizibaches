import '../../core/config/app_config.dart';
import '../../domain/models/failures.dart';
import '../../domain/models/pothole.dart';
import '../../domain/models/pothole_status.dart';
import '../demo/demo_data.dart';
import '../services/api_service.dart';

class PotholeRepository {
  PotholeRepository({required ApiService api}) : _api = api;

  final ApiService _api;

  Future<List<Pothole>> fetchAll() async {
    if (AppConfig.useDemoData) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      return DemoData.potholes();
    }

    final json = await _api.getJson('/api/potholes/geojson/');
    final features = json['features'];
    if (features is! List) {
      throw const AppFailure('La API devolvió una respuesta inesperada.');
    }

    return features
        .whereType<Map>()
        .map((feature) => _fromFeature(feature.cast<String, dynamic>()))
        .whereType<Pothole>()
        .where((pothole) => pothole.status != PotholeStatus.rejected)
        .toList(growable: false);
  }

  Pothole? _fromFeature(Map<String, dynamic> feature) {
    final geometry = feature['geometry'];
    final properties = feature['properties'];
    if (geometry is! Map || properties is! Map) return null;

    final coordinates = geometry['coordinates'];
    if (coordinates is! List || coordinates.length < 2) return null;

    final longitude = (coordinates[0] as num?)?.toDouble();
    final latitude = (coordinates[1] as num?)?.toDouble();
    if (latitude == null || longitude == null) return null;

    final props = properties.cast<String, dynamic>();
    // GeoFeatureModelSerializer pone el id en el Feature, no en properties.
    final rawId = feature['id'] ?? props['id'];
    return Pothole(
      id: (rawId as num?)?.toInt() ?? 0,
      status: PotholeStatus.fromApi(props['status'] as String?),
      severity: (props['severity'] as num?)?.toInt() ?? 1,
      reportCount: (props['report_count'] as num?)?.toInt() ?? 0,
      latitude: latitude,
      longitude: longitude,
      address: props['address'] as String? ?? '',
      firstReportedAt: _date(props['first_reported_at']),
      lastReportedAt: _date(props['last_reported_at']),
      fixedAt: _date(props['fixed_at']),
      photoUrl: props['photo_url'] as String?,
    );
  }

  DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }
}
