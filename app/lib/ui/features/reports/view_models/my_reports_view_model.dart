import 'package:flutter/foundation.dart';

import '../../../../data/repositories/report_repository.dart';
import '../../../../domain/models/failures.dart';
import '../../../../domain/models/report.dart';

class MyReportsViewModel extends ChangeNotifier {
  MyReportsViewModel({required ReportRepository repository})
    : _repository = repository;

  final ReportRepository _repository;

  List<Report> _reports = const [];
  bool _loading = false;
  String? _error;

  List<Report> get reports => _reports;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load({bool showLoader = true}) async {
    if (_loading) return;
    if (showLoader) {
      _loading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _reports = await _repository.mine();
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
    _error = null;
    notifyListeners();
  }
}
