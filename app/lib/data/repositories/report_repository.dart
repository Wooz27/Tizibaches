import '../../domain/models/failures.dart';
import '../../domain/models/report.dart';
import '../services/api_service.dart';
import 'auth_repository.dart';

class ReportRepository {
  ReportRepository({required ApiService api, required AuthRepository auth})
    : _api = api,
      _auth = auth;

  final ApiService _api;
  final AuthRepository _auth;

  Future<ReportSubmission> create(ReportDraft draft) {
    return _auth.withAccessToken((token) async {
      final json = await _api.postMultipart(
        '/api/reports/',
        token: token,
        photoBytes: draft.photoBytes,
        photoName: draft.photoName,
        fields: {
          'latitude': draft.latitude.toStringAsFixed(6),
          'longitude': draft.longitude.toStringAsFixed(6),
          'severity': draft.severity.toString(),
          'description': draft.description.trim(),
        },
      );
      return ReportSubmission.fromJson(json);
    });
  }

  Future<List<Report>> mine() {
    return _auth.withAccessToken((token) async {
      final json = await _api.getJson(
        '/api/reports/mine/',
        token: token,
        query: {'limit': '100'},
      );
      final results = json['results'];
      if (results is! List) {
        throw const AppFailure('La API devolvió una respuesta inesperada.');
      }
      return results
          .whereType<Map>()
          .map((item) => Report.fromJson(item.cast<String, dynamic>()))
          .toList(growable: false);
    });
  }
}
