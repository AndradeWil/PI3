import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/auth_providers.dart';

class StartupPage extends ConsumerWidget {
  const StartupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(sessionRestoreProvider, (previous, next) {
      next.whenData((authenticated) {
        context.go(authenticated ? '/inicio' : '/login');
      });
    });

    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.accessibility_new, size: 56),
            SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
