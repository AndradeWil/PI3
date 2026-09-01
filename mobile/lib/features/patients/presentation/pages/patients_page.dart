import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/cache/cache_providers.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../application/patient_providers.dart';
import '../../domain/entities/patient.dart';

class PatientsPage extends ConsumerStatefulWidget {
  const PatientsPage({super.key});

  @override
  ConsumerState<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends ConsumerState<PatientsPage> {
  final searchController = TextEditingController();
  Timer? debounce;
  String search = '';

  @override
  void dispose() {
    debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  void updateSearch(String value) {
    debounce?.cancel();
    debounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) setState(() => search = value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final patients = ref.watch(patientsProvider(search));
    final offline = ref.watch(
      offlineResourcesProvider.select(
        (resources) => resources.contains('patients'),
      ),
    );

    return RefreshIndicator(
      onRefresh: () => ref.refresh(patientsProvider(search).future),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: const Text('Pacientes'),
            actions: [
              IconButton(
                onPressed: () => context.push('/pacientes/novo'),
                tooltip: 'Novo paciente',
                icon: const Icon(Icons.person_add_outlined),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(child: OfflineBanner(visible: offline)),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: SearchBar(
                    controller: searchController,
                    onChanged: updateSearch,
                    hintText: 'Buscar por nome, telefone ou e-mail',
                    leading: const Icon(Icons.search),
                    trailing: [
                      if (searchController.text.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            debounce?.cancel();
                            searchController.clear();
                            setState(() => search = '');
                          },
                          tooltip: 'Limpar busca',
                          icon: const Icon(Icons.close),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          patients.when(
            data: (items) => items.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyPatients(searching: search.isNotEmpty),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    sliver: SliverList.separated(
                      itemCount: items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) => Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 760),
                          child: _PatientTile(patient: items[index]),
                        ),
                      ),
                    ),
                  ),
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => SliverFillRemaining(
              hasScrollBody: false,
              child: _PatientError(
                onRetry: () => ref.invalidate(patientsProvider(search)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PatientTile extends StatelessWidget {
  const _PatientTile({required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      patient.companyName,
      patient.phone.isEmpty ? null : patient.phone,
    ].whereType<String>().join(' | ');
    return Card(
      child: ListTile(
        minTileHeight: 72,
        leading: CircleAvatar(child: Text(patient.initials)),
        title: Text(patient.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: subtitle.isEmpty
            ? const Text('Sem contato informado')
            : Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/pacientes/${patient.id}'),
      ),
    );
  }
}

class _EmptyPatients extends StatelessWidget {
  const _EmptyPatients({required this.searching});

  final bool searching;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_search_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              searching
                  ? 'Nenhum paciente encontrado.'
                  : 'Nenhum paciente cadastrado.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _PatientError extends StatelessWidget {
  const _PatientError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('Nao foi possivel carregar os pacientes.'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}
