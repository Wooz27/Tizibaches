import 'package:flutter/foundation.dart';

import '../../../../data/repositories/report_repository.dart';
import '../../../../data/services/session_store.dart';
import '../../../../domain/models/failures.dart';
import '../../../../domain/models/pothole_status.dart';
import '../../../../domain/models/report.dart';

class MyReportsViewModel extends ChangeNotifier {
  MyReportsViewModel({
    required ReportRepository repository,
    required SessionStore store,
  }) : _repository = repository,
       _store = store;

  final ReportRepository _repository;
  final SessionStore _store;

  List<Report> _reports = const [];
  List<Report> _statusChanges = const [];
  bool _loading = false;
  String? _error;

  List<Report> get reports => _reports;
  bool get loading => _loading;
  String? get error => _error;

  List<Report> takeStatusChanges() {
    final changes = _statusChanges;
    _statusChanges = const [];
    return changes;
  }

  Future<void> load({bool showLoader = true}) async {
    if (_loading) return;
    if (showLoader) {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final previous = await _store.readReportStatuses();
      final reports = await _repository.mine();
      final current = <String, String>{};
      final changes = <Report>[];
      final now = DateTime.now();

      for (final report in reports) {
        final key = report.id.toString();
        final previousStatus = previous[key];
        current[key] = report.status.apiValue;
        final isRelevant =
            report.status == PotholeStatus.reported ||
            report.status == PotholeStatus.rejected;
        final changed = previousStatus != null
            ? previousStatus != report.status.apiValue
            : now.difference(report.createdAt) < const Duration(minutes: 10);

        if (isRelevant && changed) {
          changes.add(report);
        }
      }

      await _store.writeReportStatuses(current);
      _reports = reports;
      _statusChanges = changes;
      _error = null;
    } on AppFailure catch (failure) {
      _error = failure.message;
    } on Exception {
      _error = 'No pudimos cargar tus reportes.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => load(showLoader: false);

  void clear() {
    _reports = const [];
    _statusChanges = const [];
    _error = null;
    _store.clearReportStatuses();
    notifyListeners();
  }
}
