import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/application/auth_providers.dart';

class MorePage extends ConsumerWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CustomScrollView(
      slivers: [
        const SliverAppBar.large(title: Text('Mais')),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          sliver: SliverList.list(
            children: [
              const _SectionTitle('Gestao'),
              Card(
                child: Column(
                  children: [
                    _MenuItem(
                      icon: Icons.medical_services_outlined,
                      title: 'Atendimentos',
                      onTap: () => context.push('/atendimentos'),
                    ),
                    const Divider(height: 1, indent: 64),
                    _MenuItem(
                      icon: Icons.tune_outlined,
                      title: 'Empresas e tipos',
                      onTap: () => context.push('/cadastros'),
                    ),
                    const Divider(height: 1, indent: 64),
                    const _MenuItem(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Financeiro',
                    ),
                    const Divider(height: 1, indent: 64),
                    const _MenuItem(
                      icon: Icons.receipt_long_outlined,
                      title: 'Relatorios',
                    ),
                    const Divider(height: 1, indent: 64),
                    const _MenuItem(
                      icon: Icons.insights_outlined,
                      title: 'Inteligencia de Dados',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _SectionTitle('Conta'),
              Card(
                child: ListTile(
                  minTileHeight: 56,
                  leading: const Icon(Icons.logout),
                  title: const Text('Sair'),
                  onTap: () async {
                    await ref.read(authRepositoryProvider).logout();
                    if (context.mounted) context.go('/login');
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label, style: Theme.of(context).textTheme.titleMedium),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.title, this.onTap});

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minTileHeight: 56,
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
