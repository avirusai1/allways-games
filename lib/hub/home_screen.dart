import 'package:flutter/material.dart';

import '../app/theme/colors.dart';
import '../core/ads/banner_ad_slot.dart';
import '../games/crossword/presentation/crossword_screen.dart';
import '../games/dot_dominoes/presentation/domino_screen.dart';
import '../games/five/presentation/five_screen.dart';
import '../games/groups/presentation/groups_screen.dart';
import '../games/honeycomb/presentation/honeycomb_screen.dart';
import '../games/sudoku/presentation/sudoku_screen.dart';
import '../games/tile_match/presentation/tile_match_screen.dart';
import '../games/weave/presentation/weave_screen.dart';
import '../games/word_loop/presentation/word_loop_screen.dart';
import 'game_catalog.dart';
import 'game_glyph.dart';
import 'settings_screen.dart';

const List<String> _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

String _todayLabel(DateTime date) =>
    '${_monthNames[date.month - 1]} ${date.day}';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playable = gameCatalog.where((g) => g.enabled).toList();
    final upcoming = gameCatalog.where((g) => !g.enabled).toList();

    return Scaffold(
      bottomNavigationBar: const SafeArea(child: BannerAdSlot()),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _Header()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              sliver: SliverList.separated(
                itemCount: playable.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) => _GameTile(
                  entry: playable[index],
                  onTap: () => _openGame(context, playable[index].id),
                ),
              ),
            ),
            if (upcoming.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'COMING SOON',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                sliver: SliverList.separated(
                  itemCount: upcoming.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      _GameTile(entry: upcoming[index], onTap: null),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Allways Games',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 2),
                Text(
                  _todayLabel(DateTime.now()),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

void _openGame(BuildContext context, String gameId) {
  final screen = switch (gameId) {
    'five' => const FiveScreen(),
    'sudoku' => const SudokuScreen(),
    'word_loop' => const WordLoopScreen(),
    'honeycomb' => const HoneycombScreen(),
    'tile_match' => const TileMatchScreen(),
    'groups' => const GroupsScreen(),
    'weave' => const WeaveScreen(),
    'crossword' => const CrosswordScreen(),
    'dot_dominoes' => const DominoScreen(),
    _ => null,
  };
  if (screen == null) return;
  Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
}

/// One game, as a row rather than a card in a grid.
///
/// The grid of tall cards wasted most of its height on empty space below
/// two lines of text. A row sizes itself to its content, fits more games
/// on screen at once, and gives the tagline room to sit on one line.
class _GameTile extends StatelessWidget {
  const _GameTile({required this.entry, required this.onTap});

  final GameCatalogEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final accent = entry.accent;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.surfaceAlt),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    // A wash of the game's own colour, so each tile carries
                    // its identity without shouting.
                    color: accent.withValues(alpha: enabled ? 0.12 : 0.07),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: GameGlyph(
                      gameId: entry.id,
                      colour:
                          enabled ? accent : accent.withValues(alpha: 0.45),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.displayName,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: enabled
                                      ? AppColors.textPrimary
                                      : AppColors.textSecondary,
                                ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        entry.tagline,
                        style: Theme.of(context).textTheme.bodyMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (enabled)
                  Icon(
                    Icons.chevron_right,
                    color: accent.withValues(alpha: 0.7),
                  )
                else
                  Text(
                    'Soon',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
