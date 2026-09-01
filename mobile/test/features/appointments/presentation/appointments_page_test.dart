import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:physiomanage_mobile/features/appointments/application/appointment_providers.dart';
import 'package:physiomanage_mobile/features/appointments/domain/entities/appointment.dart';
import 'package:physiomanage_mobile/features/appointments/domain/repositories/appointment_repository.dart';
import 'package:physiomanage_mobile/features/appointments/presentation/pages/appointments_page.dart';

void main() {
  testWidgets('renders appointments returned by the repository', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appointmentRepositoryProvider.overrideWithValue(
            _AppointmentRepository(),
          ),
        ],
        child: const MaterialApp(home: AppointmentsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Maria Silva'), findsOneWidget);
    expect(find.textContaining('Fisioterapia Motora'), findsOneWidget);
    expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
  });
}

class _AppointmentRepository implements AppointmentRepository {
  static const appointment = Appointment(
    id: 1,
    patientId: 2,
    patientName: 'Maria Silva',
    companyId: 3,
    companyName: 'Empresa Vida',
    typeId: 4,
    typeName: 'Fisioterapia Motora',
    sessionValue: '120.00',
    notes: '',
    active: true,
  );

  @override
  Future<Appointment> getById(int id) async => appointment;

  @override
  Future<AppointmentOptions> getOptions() async {
    return const AppointmentOptions(patients: [], companies: [], types: []);
  }

  @override
  Future<List<Appointment>> list() async => const [appointment];

  @override
  Future<Appointment> save(AppointmentInput input, {int? id}) async =>
      appointment;
}
