import 'package:baches/core/theme/app_theme.dart';
import 'package:baches/data/repositories/auth_repository.dart';
import 'package:baches/ui/features/auth/view_models/auth_controller.dart';
import 'package:baches/ui/features/auth/views/sign_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('shows the brand, Google access and guest access', (
    tester,
  ) async {
    final auth = AuthController(repository: _MockAuthRepository());

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: SignInScreen(auth: auth),
      ),
    );

    expect(find.text('Cada bache,\nun expediente.'), findsOneWidget);
    expect(find.text('Entrar con Google'), findsOneWidget);
    expect(find.text('Explorar el mapa'), findsOneWidget);
    expect(find.textContaining('Solo Android'), findsOneWidget);
    expect(find.textContaining('iOS'), findsNothing);
  });
}
