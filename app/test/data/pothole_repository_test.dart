import 'package:baches/data/repositories/pothole_repository.dart';
import 'package:baches/data/services/api_service.dart';
import 'package:baches/domain/models/pothole_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiService extends Mock implements ApiService {}

void main() {
  late _MockApiService api;
  late PotholeRepository repository;

  setUp(() {
    api = _MockApiService();
    repository = PotholeRepository(api: api);
  });

  test('parses GeoJSON with longitude before latitude', () async {
    when(() => api.getJson('/api/potholes/geojson/')).thenAnswer(
      (_) async => {
        'type': 'FeatureCollection',
        'features': [
          {
            'type': 'Feature',
            'id': 7,
            'geometry': {
              'type': 'Point',
              'coordinates': [-88.1519, 21.1430],
            },
            'properties': {
              'name': 'El cráter',
              'status': 'in_progress',
              'severity': 3,
              'report_count': 4,
              'note': 'Hueco profundo junto al paso peatonal.',
              'address': 'Calle 51 #812, Centro',
              'first_reported_at': '2026-10-01T12:00:00Z',
              'last_reported_at': '2026-10-30T12:00:00Z',
              'fixed_at': null,
              'photo_url': null,
            },
          },
        ],
      },
    );

    final potholes = await repository.fetchAll();

    expect(potholes, hasLength(1));
    expect(potholes.single.latitude, 21.1430);
    expect(potholes.single.longitude, -88.1519);
    expect(potholes.single.name, 'El cráter');
    expect(potholes.single.note, 'Hueco profundo junto al paso peatonal.');
    expect(potholes.single.status, PotholeStatus.inProgress);
    expect(potholes.single.address, 'Calle 51 #812, Centro');
    expect(potholes.single.reportCount, 4);
  });

  test('ignores malformed features without coordinates', () async {
    when(() => api.getJson('/api/potholes/geojson/')).thenAnswer(
      (_) async => {
        'features': [
          {
            'type': 'Feature',
            'properties': {'id': 1},
          },
          {
            'geometry': {
              'coordinates': [-88.1, 21.1],
            },
            'properties': {'id': 2, 'status': 'reported'},
          },
        ],
      },
    );

    final potholes = await repository.fetchAll();

    expect(potholes, hasLength(1));
    expect(potholes.single.id, 2);
  });
}
