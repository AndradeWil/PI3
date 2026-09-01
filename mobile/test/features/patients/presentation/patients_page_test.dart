import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physiomanage_mobile/features/patients/application/patient_providers.dart';
import 'package:physiomanage_mobile/features/patients/domain/entities/patient.dart';
import 'package:physiomanage_mobile/features/patients/domain/repositories/patient_repository.dart';
import 'package:physiomanage_mobile/features/patients/presentation/pages/patients_page.dart';

void main() {
  testWidgets('renders patients returned by the repository', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          patientRepositoryProvider.overrideWithValue(_PatientRepository()),
        ],
        child: const MaterialApp(home: Scaffold(body: PatientsPage())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Maria Silva'), findsOneWidget);
    expect(find.text('Empresa Vida | 11999990000'), findsOneWidget);
    expect(find.byType(SearchBar), findsOneWidget);
  });
}

class _PatientRepository implements PatientRepository {
  static const patient = Patient(
    id: 1,
    name: 'Maria Silva',
    age: 68,
    phone: '11999990000',
    email: 'maria@example.com',
    address: 'Rua A, 10',
    clinicalCondition: 'Pos-operatorio',
    dailyFrequency: 1,
    companyName: 'Empresa Vida',
  );

  @override
  Future<Patient> getById(int id) async => patient;

  @override
  Future<List<Patient>> list({String search = ''}) async => const [patient];

  @override
  Future<Patient> save(PatientInput input, {int? id}) async => patient;
}
