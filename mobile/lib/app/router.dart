import 'package:go_router/go_router.dart';

import '../features/appointments/presentation/pages/appointment_detail_page.dart';
import '../features/appointments/presentation/pages/appointment_form_page.dart';
import '../features/appointments/presentation/pages/appointments_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/startup_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/finance/presentation/pages/finance_page.dart';
import '../features/intelligence/presentation/pages/data_intelligence_page.dart';
import '../features/more/presentation/pages/more_page.dart';
import '../features/patients/presentation/pages/patient_detail_page.dart';
import '../features/patients/presentation/pages/patient_form_page.dart';
import '../features/patients/presentation/pages/patients_page.dart';
import '../features/registries/presentation/pages/registries_page.dart';
import '../features/reports/presentation/pages/reports_page.dart';
import '../features/schedule/presentation/pages/schedule_page.dart';
import 'shell/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const StartupPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/financeiro',
      builder: (context, state) => const FinancePage(),
    ),
    GoRoute(
      path: '/relatorios',
      builder: (context, state) => const ReportsPage(),
    ),
    GoRoute(
      path: '/inteligencia',
      builder: (context, state) => const DataIntelligencePage(),
    ),
    GoRoute(
      path: '/cadastros',
      builder: (context, state) => const RegistriesPage(),
    ),
    GoRoute(
      path: '/atendimentos',
      builder: (context, state) => const AppointmentsPage(),
      routes: [
        GoRoute(
          path: 'novo',
          builder: (context, state) => const AppointmentFormPage(),
        ),
        GoRoute(
          path: ':id',
          builder: (context, state) => AppointmentDetailPage(
            appointmentId: int.parse(state.pathParameters['id']!),
          ),
          routes: [
            GoRoute(
              path: 'editar',
              builder: (context, state) => AppointmentFormPage(
                appointmentId: int.parse(state.pathParameters['id']!),
              ),
            ),
          ],
        ),
      ],
    ),
    ShellRoute(
      builder: (context, state, child) =>
          AppShell(currentLocation: state.uri.path, child: child),
      routes: [
        GoRoute(
          path: '/inicio',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DashboardPage()),
        ),
        GoRoute(
          path: '/agenda',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SchedulePage()),
        ),
        GoRoute(
          path: '/pacientes',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: PatientsPage()),
          routes: [
            GoRoute(
              path: 'novo',
              builder: (context, state) => const PatientFormPage(),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) => PatientDetailPage(
                patientId: int.parse(state.pathParameters['id']!),
              ),
              routes: [
                GoRoute(
                  path: 'editar',
                  builder: (context, state) => PatientFormPage(
                    patientId: int.parse(state.pathParameters['id']!),
                  ),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: '/mais',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: MorePage()),
        ),
      ],
    ),
  ],
);
