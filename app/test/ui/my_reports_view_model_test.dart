import 'package:baches/data/repositories/report_repository.dart';
import 'package:baches/data/services/session_store.dart';
import 'package:baches/domain/models/pothole_status.dart';
import 'package:baches/domain/models/report.dart';
import 'package:baches/ui/features/reports/view_models/my_reports_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockReportRepository extends Mock implements ReportRepository {}

class _MockSessionStore extends Mock implements SessionStore {}

Report _report({
  required PotholeStatus status,
  DateTime? createdAt,
}) {
  return Report(
    id: 10,
    potholeId: 4,
    status: status,
    severity: 2,
    description: 'Hueco profundo.',
    createdAt: createdAt ?? DateTime.now().subtract(const Duration(hours: 1)),
  );
}

void main() {
  late _MockReportRepository repository;
  late _MockSessionStore store;
  late MyReportsViewModel viewModel;

  setUp(() {
    repository = _MockReportRepository();
    store = _MockSessionStore();
    viewModel = MyReportsViewModel(repository: repository, store: store);
    when(() => store.writeReportStatuses(any())).thenAnswer((_) async {});
  });

  test('notifies when a report becomes reported', () async {
    when(() => store.readReportStatuses()).thenAnswer(
      (_) async => {'10': 'pending'},
    );
    when(() => repository.mine()).thenAnswer(
      (_) async => [_report(status: PotholeStatus.reported)],
    );

    await viewModel.load();

    expect(viewModel.takeStatusChanges().single.id, 10);
    expect(viewModel.takeStatusChanges(), isEmpty);
  });

  test('notifies when a report becomes rejected', () async {
    when(() => store.readReportStatuses()).thenAnswer(
      (_) async => {'10': 'pending'},
    );
    when(() => repository.mine()).thenAnswer(
      (_) async => [_report(status: PotholeStatus.rejected)],
    );

    await viewModel.load();

    expect(viewModel.takeStatusChanges().single.id, 10);
  });

  test('does not notify for other statuses', () async {
    when(() => store.readReportStatuses()).thenAnswer(
      (_) async => {'10': 'reported'},
    );
    when(() => repository.mine()).thenAnswer(
      (_) async => [_report(status: PotholeStatus.inProgress)],
    );

    await viewModel.load();

    expect(viewModel.takeStatusChanges(), isEmpty);
  });

  test('does not repeat the notification when the status did not change', () async {
    when(() => store.readReportStatuses()).thenAnswer(
      (_) async => {'10': 'reported'},
    );
    when(() => repository.mine()).thenAnswer(
      (_) async => [_report(status: PotholeStatus.reported)],
    );

    await viewModel.load();

    expect(viewModel.takeStatusChanges(), isEmpty);
  });
}
