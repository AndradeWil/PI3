import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physiomanage_mobile/features/registries/application/registry_providers.dart';
import 'package:physiomanage_mobile/features/registries/domain/entities/registry_entities.dart';
import 'package:physiomanage_mobile/features/registries/domain/repositories/registry_repository.dart';
import 'package:physiomanage_mobile/features/registries/presentation/pages/registries_page.dart';

void main() {
  testWidgets('renders company and service type tabs', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          registryRepositoryProvider.overrideWithValue(_RegistryRepository()),
        ],
        child: const MaterialApp(home: RegistriesPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Empresa Vida'), findsOneWidget);
    await tester.tap(find.text('Tipos'));
    await tester.pumpAndSettle();
    expect(find.text('Fisioterapia Motora'), findsOneWidget);
  });
}

class _RegistryRepository implements RegistryRepository {
  @override
  Future<void> deleteCompany(int id) async {}

  @override
  Future<void> deleteServiceType(int id) async {}

  @override
  Future<List<Company>> listCompanies() async => const [
    Company(
      id: 1,
      name: 'Empresa Vida',
      contact: 'Ana',
      phone: '11999990000',
      email: 'ana@example.com',
    ),
  ];

  @override
  Future<List<ServiceType>> listServiceTypes() async => const [
    ServiceType(
      id: 2,
      name: 'Fisioterapia Motora',
      description: 'Atendimento domiciliar',
      defaultValue: '120.00',
    ),
  ];

  @override
  Future<Company> saveCompany(CompanyInput input, {int? id}) async {
    return (await listCompanies()).first;
  }

  @override
  Future<ServiceType> saveServiceType(ServiceTypeInput input, {int? id}) async {
    return (await listServiceTypes()).first;
  }
}
