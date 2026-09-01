import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../appointments/application/appointment_providers.dart';
import '../../application/registry_providers.dart';
import '../../domain/entities/registry_entities.dart';
import '../../domain/repositories/registry_repository.dart';

class RegistriesPage extends ConsumerStatefulWidget {
  const RegistriesPage({super.key});

  @override
  ConsumerState<RegistriesPage> createState() => _RegistriesPageState();
}

class _RegistriesPageState extends ConsumerState<RegistriesPage>
    with SingleTickerProviderStateMixin {
  late final TabController tabController = TabController(length: 2, vsync: this)
    ..addListener(() {
      if (!tabController.indexIsChanging) setState(() {});
    });

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  void refreshDependencies() {
    ref.invalidate(companiesProvider);
    ref.invalidate(serviceTypesProvider);
    ref.invalidate(appointmentOptionsProvider);
  }

  Future<void> addCurrent() async {
    final changed = tabController.index == 0
        ? await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (context) => const _CompanyForm(),
          )
        : await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (context) => const _ServiceTypeForm(),
          );
    if (changed == true) refreshDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastros'),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: 'Empresas'),
            Tab(text: 'Tipos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _CompaniesTab(onChanged: refreshDependencies),
          _ServiceTypesTab(onChanged: refreshDependencies),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: addCurrent,
        icon: const Icon(Icons.add),
        label: Text(tabController.index == 0 ? 'Nova empresa' : 'Novo tipo'),
      ),
    );
  }
}

class _CompaniesTab extends ConsumerWidget {
  const _CompaniesTab({required this.onChanged});

  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AsyncRegistryList<Company>(
      value: ref.watch(companiesProvider),
      emptyMessage: 'Nenhuma empresa cadastrada.',
      itemBuilder: (company) => _RegistryTile(
        icon: Icons.business_outlined,
        title: company.name,
        subtitle: [
          company.contact,
          company.phone,
        ].where((value) => value.isNotEmpty).join(' | '),
        onTap: () async {
          final changed = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (context) => _CompanyForm(company: company),
          );
          if (changed == true) onChanged();
        },
        onDelete: () => _delete(
          context,
          ref,
          label: company.name,
          action: () =>
              ref.read(registryRepositoryProvider).deleteCompany(company.id),
          onChanged: onChanged,
        ),
      ),
      onRetry: () => ref.invalidate(companiesProvider),
    );
  }
}

class _ServiceTypesTab extends ConsumerWidget {
  const _ServiceTypesTab({required this.onChanged});

  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AsyncRegistryList<ServiceType>(
      value: ref.watch(serviceTypesProvider),
      emptyMessage: 'Nenhum tipo de atendimento cadastrado.',
      itemBuilder: (type) => _RegistryTile(
        icon: Icons.medical_information_outlined,
        title: type.name,
        subtitle: type.defaultValue == null
            ? 'Sem valor padrao'
            : 'R\$ ${type.defaultValue!.replaceAll('.', ',')}',
        onTap: () async {
          final changed = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            showDragHandle: true,
            builder: (context) => _ServiceTypeForm(serviceType: type),
          );
          if (changed == true) onChanged();
        },
        onDelete: () => _delete(
          context,
          ref,
          label: type.name,
          action: () =>
              ref.read(registryRepositoryProvider).deleteServiceType(type.id),
          onChanged: onChanged,
        ),
      ),
      onRetry: () => ref.invalidate(serviceTypesProvider),
    );
  }
}

Future<void> _delete(
  BuildContext context,
  WidgetRef ref, {
  required String label,
  required Future<void> Function() action,
  required VoidCallback onChanged,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Confirmar exclusao'),
      content: Text('Deseja excluir "$label"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Excluir'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await action();
    onChanged();
  } on RegistryFailure catch (error) {
    if (!context.mounted) return;
    final message = error.protected
        ? 'Este tipo esta vinculado a um atendimento.'
        : 'Nao foi possivel excluir o cadastro.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _AsyncRegistryList<T> extends StatelessWidget {
  const _AsyncRegistryList({
    required this.value,
    required this.itemBuilder,
    required this.emptyMessage,
    required this.onRetry,
  });

  final AsyncValue<List<T>> value;
  final Widget Function(T) itemBuilder;
  final String emptyMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (items) => items.isEmpty
          ? Center(child: Text(emptyMessage))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) => Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: itemBuilder(items[index]),
                ),
              ),
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Tentar novamente'),
        ),
      ),
    );
  }
}

class _RegistryTile extends StatelessWidget {
  const _RegistryTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.onDelete,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        minTileHeight: 72,
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle.isEmpty ? 'Sem detalhes informados' : subtitle),
        onTap: onTap,
        trailing: IconButton(
          onPressed: onDelete,
          tooltip: 'Excluir',
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}

class _CompanyForm extends ConsumerStatefulWidget {
  const _CompanyForm({this.company});

  final Company? company;

  @override
  ConsumerState<_CompanyForm> createState() => _CompanyFormState();
}

class _CompanyFormState extends ConsumerState<_CompanyForm> {
  final formKey = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.company?.name);
  late final contact = TextEditingController(text: widget.company?.contact);
  late final phone = TextEditingController(text: widget.company?.phone);
  late final email = TextEditingController(text: widget.company?.email);
  bool saving = false;

  @override
  void dispose() {
    name.dispose();
    contact.dispose();
    phone.dispose();
    email.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await ref
          .read(registryRepositoryProvider)
          .saveCompany(
            CompanyInput(
              name: name.text.trim(),
              contact: contact.text.trim(),
              phone: phone.text.trim(),
              email: email.text.trim(),
            ),
            id: widget.company?.id,
          );
      if (mounted) Navigator.pop(context, true);
    } on RegistryFailure {
      if (mounted) _showSaveError(context);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => _FormShell(
    title: widget.company == null ? 'Nova empresa' : 'Editar empresa',
    formKey: formKey,
    saving: saving,
    onSave: save,
    children: [
      _requiredText(name, 'Nome *'),
      _text(contact, 'Contato'),
      _text(phone, 'Telefone', keyboardType: TextInputType.phone),
      _text(email, 'E-mail', keyboardType: TextInputType.emailAddress),
    ],
  );
}

class _ServiceTypeForm extends ConsumerStatefulWidget {
  const _ServiceTypeForm({this.serviceType});

  final ServiceType? serviceType;

  @override
  ConsumerState<_ServiceTypeForm> createState() => _ServiceTypeFormState();
}

class _ServiceTypeFormState extends ConsumerState<_ServiceTypeForm> {
  final formKey = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.serviceType?.name);
  late final description = TextEditingController(
    text: widget.serviceType?.description,
  );
  late final value = TextEditingController(
    text: widget.serviceType?.defaultValue,
  );
  bool saving = false;

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    value.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    setState(() => saving = true);
    try {
      await ref
          .read(registryRepositoryProvider)
          .saveServiceType(
            ServiceTypeInput(
              name: name.text.trim(),
              description: description.text.trim(),
              defaultValue: value.text.trim().isEmpty
                  ? null
                  : value.text.replaceAll(',', '.'),
            ),
            id: widget.serviceType?.id,
          );
      if (mounted) Navigator.pop(context, true);
    } on RegistryFailure {
      if (mounted) _showSaveError(context);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => _FormShell(
    title: widget.serviceType == null ? 'Novo tipo' : 'Editar tipo',
    formKey: formKey,
    saving: saving,
    onSave: save,
    children: [
      _requiredText(name, 'Nome *'),
      _text(description, 'Descricao', minLines: 3),
      TextFormField(
        controller: value,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'Valor padrao'),
        validator: (text) {
          if (text == null || text.isEmpty) return null;
          return num.tryParse(text.replaceAll(',', '.')) == null
              ? 'Informe um valor valido.'
              : null;
        },
      ),
    ],
  );
}

class _FormShell extends StatelessWidget {
  const _FormShell({
    required this.title,
    required this.formKey,
    required this.saving,
    required this.onSave,
    required this.children,
  });

  final String title;
  final GlobalKey<FormState> formKey;
  final bool saving;
  final VoidCallback onSave;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index < children.length - 1) const SizedBox(height: 12),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: saving ? null : onSave,
                icon: saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(saving ? 'Salvando...' : 'Salvar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

TextFormField _requiredText(TextEditingController controller, String label) {
  return _text(
    controller,
    label,
    validator: (value) =>
        value == null || value.trim().isEmpty ? 'Campo obrigatorio.' : null,
  );
}

TextFormField _text(
  TextEditingController controller,
  String label, {
  TextInputType? keyboardType,
  int minLines = 1,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    minLines: minLines,
    maxLines: minLines == 1 ? 1 : 5,
    decoration: InputDecoration(labelText: label),
    validator: validator,
  );
}

void _showSaveError(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Nao foi possivel salvar. Verifique os dados.'),
    ),
  );
}
