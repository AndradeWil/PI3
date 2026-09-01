import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    required this.currentLocation,
    required this.child,
    super.key,
  });

  static const destinations = [
    _Destination('/inicio', 'Inicio', Icons.home_outlined, Icons.home),
    _Destination(
      '/agenda',
      'Agenda',
      Icons.calendar_month_outlined,
      Icons.calendar_month,
    ),
    _Destination('/pacientes', 'Pacientes', Icons.people_outline, Icons.people),
    _Destination('/mais', 'Mais', Icons.grid_view_outlined, Icons.grid_view),
  ];

  final String currentLocation;
  final Widget child;

  int get selectedIndex {
    final index = destinations.indexWhere(
      (destination) => currentLocation.startsWith(destination.path),
    );
    return index < 0 ? 0 : index;
  }

  void navigate(BuildContext context, int index) {
    context.go(destinations[index].path);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 840;
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                if (useRail)
                  NavigationRail(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (index) => navigate(context, index),
                    labelType: NavigationRailLabelType.all,
                    leading: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: _BrandMark(),
                    ),
                    destinations: [
                      for (final destination in destinations)
                        NavigationRailDestination(
                          icon: Icon(destination.icon),
                          selectedIcon: Icon(destination.selectedIcon),
                          label: Text(destination.label),
                        ),
                    ],
                  ),
                Expanded(child: child),
              ],
            ),
          ),
          bottomNavigationBar: useRail
              ? null
              : NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) => navigate(context, index),
                  destinations: [
                    for (final destination in destinations)
                      NavigationDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: destination.label,
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class FeaturePlaceholder extends StatelessWidget {
  const FeaturePlaceholder({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar.large(title: Text(title)),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(description, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    const Text('Modulo em desenvolvimento.'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.accessibility_new, color: Colors.white),
    );
  }
}

class _Destination {
  const _Destination(this.path, this.label, this.icon, this.selectedIcon);

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
