import 'package:flutter/material.dart';

/// The 9-game roster. Display names are deliberately original — not NYT's
/// specific product names (several of which, beyond "Wordle", are likely
/// trademarked: Connections, Strands, Letter Boxed, Pips). Only genuinely
/// generic genre terms (Crossword, Sudoku) are reused as-is.
class GameCatalogEntry {
  const GameCatalogEntry({
    required this.id,
    required this.displayName,
    required this.tagline,
    required this.icon,
    this.enabled = false,
  });

  final String id;
  final String displayName;
  final String tagline;
  final IconData icon;
  final bool enabled;
}

const List<GameCatalogEntry> gameCatalog = [
  GameCatalogEntry(
    id: 'five',
    displayName: 'Five',
    tagline: 'Guess the word in 6 tries',
    icon: Icons.grid_on_rounded,
    enabled: true,
  ),
  GameCatalogEntry(
    id: 'sudoku',
    displayName: 'Sudoku',
    tagline: 'Fill the grid, no repeats',
    icon: Icons.apps_rounded,
  ),
  GameCatalogEntry(
    id: 'word_loop',
    displayName: 'Word Loop',
    tagline: 'Chain words around the box',
    icon: Icons.hexagon_outlined,
  ),
  GameCatalogEntry(
    id: 'honeycomb',
    displayName: 'Honeycomb',
    tagline: 'Find words from 7 letters',
    icon: Icons.change_history_rounded,
  ),
  GameCatalogEntry(
    id: 'tile_match',
    displayName: 'Tile Match',
    tagline: 'Clear the board in pairs',
    icon: Icons.dashboard_customize_rounded,
  ),
  GameCatalogEntry(
    id: 'groups',
    displayName: 'Groups',
    tagline: 'Find four groups of four',
    icon: Icons.grain_rounded,
  ),
  GameCatalogEntry(
    id: 'weave',
    displayName: 'Weave',
    tagline: 'Trace the hidden theme words',
    icon: Icons.gesture_rounded,
  ),
  GameCatalogEntry(
    id: 'crossword',
    displayName: 'Crossword',
    tagline: 'Classic clues, daily grid',
    icon: Icons.border_all_rounded,
  ),
  GameCatalogEntry(
    id: 'dot_dominoes',
    displayName: 'Dot Dominoes',
    tagline: 'Place dominoes to fit each region',
    icon: Icons.casino_outlined,
  ),
];
