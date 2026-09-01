import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physiomanage_mobile/app/app.dart';
import 'package:physiomanage_mobile/features/auth/application/auth_providers.dart';
import 'package:physiomanage_mobile/features/auth/domain/repositories/auth_repository.dart';

void main() {
  testWidgets('shows the production login form', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_SignedOutAuthRepository()),
        ],
        child: const PhysioManageApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('PhysioManage'), findsOneWidget);
    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Senha'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
  });
}

class _SignedOutAuthRepository implements AuthRepository {
  @override
  Future<void> login({
    required String username,
    required String password,
  }) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<bool> restoreSession() async => false;
}
