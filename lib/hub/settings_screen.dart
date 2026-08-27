import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/iap/entitlements.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlements = ref.watch(entitlementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          children: [
            entitlements.when(
              loading: () => const ListTile(
                title: Text('Remove ads'),
                subtitle: Text('Checking your purchases…'),
              ),
              error: (_, _) => const ListTile(
                title: Text('Remove ads'),
                subtitle: Text('Could not reach the store'),
              ),
              data: (value) => value.adsRemoved
                  ? const ListTile(
                      leading: Icon(Icons.check_circle_outline),
                      title: Text('Ads removed'),
                      subtitle: Text('Thank you for supporting the app.'),
                    )
                  : ListTile(
                      leading: const Icon(Icons.block_outlined),
                      title: const Text('Remove ads'),
                      subtitle: const Text('One-off purchase.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final started = await ref
                            .read(entitlementsProvider.notifier)
                            .buyRemoveAds();
                        if (!started && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Store is unavailable right now.'),
                            ),
                          );
                        }
                      },
                    ),
            ),
            // Restoring must be reachable even when a purchase is already
            // recognised: both stores require it, and a player on a new
            // device needs it to get their purchase back.
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Restore purchases'),
              onTap: () async {
                await ref.read(entitlementsProvider.notifier).restore();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Checked for purchases.')),
                  );
                }
              },
            ),
            const Divider(),
            const AboutListTile(
              icon: Icon(Icons.info_outline),
              applicationName: 'Allways Games',
              applicationLegalese:
                  'Original puzzles and artwork. Word lists derived from '
                  'the public-domain ENABLE1 list.',
            ),
          ],
        ),
      ),
    );
  }
}
