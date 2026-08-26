import 'package:flutter/material.dart';

import '../app/theme/colors.dart';
import '../games/five/presentation/five_screen.dart';
import '../games/sudoku/presentation/sudoku_screen.dart';
import '../games/word_loop/presentation/word_loop_screen.dart';
import 'game_catalog.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Allways Games'),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              sliver: SliverToBoxAdapter(
                child: Text(
                  'Daily word & puzzle games',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _GameTile(entry: gameCatalog[index]),
                  childCount: gameCatalog.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _openGame(BuildContext context, String gameId) {
  final screen = switch (gameId) {
    'five' => const FiveScreen(),
    'sudoku' => const SudokuScreen(),
    'word_loop' => const WordLoopScreen(),
    _ => null,
  };
  if (screen == null) return;
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.entry});

  final GameCatalogEntry entry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: entry.enabled ? () => _openGame(context, entry.id) : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(entry.icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(height: 12),
              Text(entry.displayName, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                entry.enabled ? entry.tagline : 'Coming soon',
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
