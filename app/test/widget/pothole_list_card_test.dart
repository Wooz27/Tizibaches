import 'package:baches/core/theme/app_theme.dart';
import 'package:baches/domain/models/pothole.dart';
import 'package:baches/domain/models/pothole_status.dart';
import 'package:baches/ui/features/map/views/pothole_list_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  testWidgets('the whole card opens the pothole, not only the image', (
    tester,
  ) async {
    await initializeDateFormatting('es_MX');
    var opened = false;
    const pothole = Pothole(
      id: 7,
      status: PotholeStatus.reported,
      severity: 3,
      reportCount: 2,
      latitude: 21.143,
      longitude: -88.1519,
      address: 'Calle 51 #812, Centro',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: PotholeListCard(
              pothole: pothole,
              onTap: () => opened = true,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Calle 51 #812, Centro'));
    await tester.pump();

    expect(opened, isTrue);
    expect(find.text('Abrir ficha'), findsOneWidget);
  });
}
