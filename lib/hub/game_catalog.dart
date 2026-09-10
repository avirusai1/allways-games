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
    required this.accent,
    this.enabled = false,
  });

  final String id;
  final String displayName;
  final String tagline;

  /// Each game's own colour, used for its glyph and tile wash.
  ///
  /// Nine tiles in one house colour read as an undifferentiated list; a
  /// distinct hue per game is what makes the board scannable and gives
  /// each game somewhere to carry its identity inside its own screens.
  final Color accent;

  final bool enabled;
}

const List<GameCatalogEntry> gameCatalog = [
  GameCatalogEntry(
    id: 'five',
    displayName: 'Five',
    tagline: 'Pick a difficulty, play as many as you like',
    accent: Color(0xFF2E7D5B),
    enabled: true,
  ),
  GameCatalogEntry(
    id: 'sudoku',
    displayName: 'Sudoku',
    tagline: 'Pick a difficulty, play as many as you like',
    accent: Color(0xFF3D5A99),
    enabled: true,
  ),
  GameCatalogEntry(
    id: 'word_loop',
    displayName: 'Word Loop',
    tagline: 'Pick a difficulty, play as many as you like',
    accent: Color(0xFF1F7A6B),
    enabled: true,
  ),
  GameCatalogEntry(
    id: 'honeycomb',
    displayName: 'Honeycomb',
    tagline: 'Pick a difficulty, play as many as you like',
    accent: Color(0xFFD98324),
    enabled: true,
  ),
  GameCatalogEntry(
    id: 'tile_match',
    displayName: 'Tile Match',
    tagline: 'Pick a board size, play as many as you like',
    accent: Color(0xFFC4553D),
    enabled: true,
  ),
  GameCatalogEntry(
    id: 'groups',
    displayName: 'Groups',
    tagline: 'Play as many puzzles as you like',
    accent: Color(0xFF7B4B7E),
    enabled: true,
  ),
  GameCatalogEntry(
    id: 'weave',
    displayName: 'Weave',
    tagline: 'Pick a difficulty, play as many as you like',
    accent: Color(0xFF2A7B8C),
    enabled: true,
  ),
  GameCatalogEntry(
    id: 'crossword',
    displayName: 'Crossword',
    tagline: 'Pick a difficulty, play as many as you like',
    accent: Color(0xFF5A6472),
    enabled: true,
  ),
  GameCatalogEntry(
    id: 'dot_dominoes',
    displayName: 'Dot Dominoes',
    tagline: 'Pick a difficulty, play as many as you like',
    accent: Color(0xFFA85434),
    enabled: true,
  ),
];
