import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/startup_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/more/presentation/pages/more_page.dart';
import 'shell/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const StartupPage()),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
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
          pageBuilder: (context, state) => const NoTransitionPage(
            child: FeaturePlaceholder(
              icon: Icons.calendar_month_outlined,
              title: 'Agenda',
              description: 'Organize as visitas e registre suas sessoes.',
            ),
          ),
        ),
        GoRoute(
          path: '/pacientes',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: FeaturePlaceholder(
              icon: Icons.people_outline,
              title: 'Pacientes',
              description: 'Consulte e atualize os dados dos pacientes.',
            ),
          ),
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
