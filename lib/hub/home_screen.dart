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

/// The hub.
///
/// A plain list of rows read as a settings screen rather than somewhere
/// you go to play. This is a bento instead: one game gets a wide card as
/// the day's opener, the rest sit in a two-column mosaic, and every tile
/// is washed in its own colour so the board reads as nine distinct games
/// rather than nine entries.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playable = gameCatalog.where((g) => g.enabled).toList();
    final upcoming = gameCatalog.where((g) => !g.enabled).toList();

    // The featured slot rotates by date, so the hub is not identical
    // every morning and every game gets its turn at the top.
    final today = DateTime.now();
    final featured = playable.isEmpty
        ? null
        : playable[today.difference(DateTime(2024)).inDays % playable.length];
    final rest = playable.where((g) => g != featured).toList();

    return Scaffold(
      bottomNavigationBar: const SafeArea(child: BannerAdSlot()),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _Header()),
            if (featured != null)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                sliver: SliverToBoxAdapter(
                  child: _FeaturedCard(
                    entry: featured,
                    onTap: () => _openGame(context, featured.id),
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _GameCard(
                    entry: rest[index],
                    onTap: () => _openGame(context, rest[index].id),
                  ),
                  childCount: rest.length,
                ),
              ),
            ),
            if (upcoming.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _GameCard(entry: upcoming[index], onTap: null),
                    childCount: upcoming.length,
                  ),
                ),
              ),
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
      padding: const EdgeInsets.fromLTRB(20, 10, 12, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _todayLabel(DateTime.now()).toUpperCase(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 11,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Allways Games',
                  style: Theme.of(context).textTheme.displaySmall,
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

/// The day's opener: full width, its glyph big enough to be an image
/// rather than an icon.
class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({required this.entry, required this.onTap});

  final GameCatalogEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = entry.accent;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.16),
                accent.withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(color: accent.withValues(alpha: 0.22)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "TODAY'S PICK",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 10,
                              letterSpacing: 1.4,
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.displayName,
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(height: 1.1),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.tagline,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'Play',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                GameGlyph(gameId: entry.id, colour: accent, size: 76),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One game in the mosaic.
class _GameCard extends StatelessWidget {
  const _GameCard({required this.entry, required this.onTap});

  final GameCatalogEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final accent = entry.accent;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: accent.withValues(alpha: enabled ? 0.10 : 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: accent.withValues(alpha: enabled ? 0.18 : 0.10),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GameGlyph(
                      gameId: entry.id,
                      colour: enabled ? accent : accent.withValues(alpha: 0.45),
                      size: 30,
                    ),
                    const Spacer(),
                    if (!enabled)
                      Text(
                        'SOON',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 9,
                              letterSpacing: 0.8,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  entry.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: enabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  entry.tagline,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 12, height: 1.25),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
