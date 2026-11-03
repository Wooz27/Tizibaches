import 'package:baches/domain/models/pothole_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PotholeStatus', () {
    test('maps every backend status', () {
      expect(PotholeStatus.fromApi('pending'), PotholeStatus.pending);
      expect(PotholeStatus.fromApi('reported'), PotholeStatus.reported);
      expect(PotholeStatus.fromApi('verified'), PotholeStatus.verified);
      expect(PotholeStatus.fromApi('scheduled'), PotholeStatus.scheduled);
      expect(PotholeStatus.fromApi('in_progress'), PotholeStatus.inProgress);
      expect(PotholeStatus.fromApi('fixed'), PotholeStatus.fixed);
      expect(PotholeStatus.fromApi('rejected'), PotholeStatus.rejected);
    });

    test('unknown status is contained instead of crashing', () {
      expect(PotholeStatus.fromApi('archived'), PotholeStatus.unknown);
      expect(PotholeStatus.unknown.label, 'Sin estado');
    });
  });
}
