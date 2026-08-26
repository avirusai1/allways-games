// Offline content generator for the "Five" game (Wordle-style).
//
// Produces assets/content/five/bank.json: a curated "answers" list (common
// words only, so every daily puzzle is fair/familiar) and a much larger
// "validGuesses" list (any real 5-letter word, so players aren't blocked
// from typing legitimate guesses). Run with:
//   dart run tool/gen_five_bank.dart
//
// Sources (both public domain / freely redistributable, never NYT's data):
//   - tool/data/enable1.txt   : ENABLE1 word list
//   - tool/data/count_1w.txt  : Peter Norvig's word-frequency list
//     (derived from the Google Books Ngram corpus), used only to rank
//     ENABLE1 words by real-world commonness for the answer subset.
import 'dart:convert';
import 'dart:io';
import 'dart:math';

// Words that are valid dictionary entries but unfit as a daily *answer*
// (slurs, crude/vulgar terms, or otherwise inappropriate for a general
// puzzle audience). They remain valid guesses since real 5-letter words
// shouldn't be rejected as input, but are excluded from the answer pool.
const Set<String> _answerDenylist = {
  'bitch', 'boobs', 'crappy', 'damns', 'fucks', 'nigga', 'niggr', 'pissy',
  'shits', 'twats', 'wanky', 'whore', 'spick', 'spics', 'chink', 'chinks',
  'gypsy', 'gyppo', 'kraut', 'kikes', 'wetba', 'injun',
};

const int answerPoolSize = 1500;

void main() {
  final enable1File = File('tool/data/enable1.txt');
  final freqFile = File('tool/data/count_1w.txt');
  if (!enable1File.existsSync() || !freqFile.existsSync()) {
    stderr.writeln('Missing tool/data/enable1.txt or tool/data/count_1w.txt');
    exit(1);
  }

  final fiveLetterWordPattern = RegExp(r'^[a-z]{5}$');

  final validGuesses = enable1File
      .readAsLinesSync()
      .map((w) => w.trim().toLowerCase())
      .where((w) => fiveLetterWordPattern.hasMatch(w))
      .toSet();

  final frequency = <String, int>{};
  for (final line in freqFile.readAsLinesSync()) {
    final parts = line.split('\t');
    if (parts.length != 2) continue;
    final word = parts[0].trim().toLowerCase();
    if (!fiveLetterWordPattern.hasMatch(word)) continue;
    if (!validGuesses.contains(word)) continue;
    frequency[word] = int.tryParse(parts[1].trim()) ?? 0;
  }

  final rankedByFrequency = frequency.keys.toList()
    ..sort((a, b) => frequency[b]!.compareTo(frequency[a]!));

  final answerCandidates = rankedByFrequency
      .where((w) => !_answerDenylist.contains(w))
      .take(answerPoolSize)
      .toList();

  if (answerCandidates.length < answerPoolSize) {
    stderr.writeln(
      'Warning: only found ${answerCandidates.length} common 5-letter '
      'words (wanted $answerPoolSize). Proceeding anyway.',
    );
  }

  // Deterministic shuffle (fixed seed) so today's answer order is not
  // simply "most common word first" for years, but regenerating this
  // script produces the exact same bank every time.
  final rng = Random(20240101);
  final answers = List<String>.from(answerCandidates)..shuffle(rng);

  final sortedGuesses = validGuesses.toList()..sort();

  final bank = {
    'schemaVersion': 1,
    'game': 'five',
    'generatedAt': '2024-01-01T00:00:00Z',
    'answers': answers,
    'validGuesses': sortedGuesses,
  };

  final outDir = Directory('assets/content/five');
  outDir.createSync(recursive: true);
  final outFile = File('${outDir.path}/bank.json');
  outFile.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(bank));

  stdout.writeln(
    'Wrote ${outFile.path}: ${answers.length} answers, '
    '${sortedGuesses.length} valid guesses.',
  );
}
