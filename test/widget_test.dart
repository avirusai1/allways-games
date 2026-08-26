import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:allways_games/app/app.dart';

void main() {
  testWidgets('Home screen renders the full 9-game catalog', (tester) async {
    // Tall surface so the whole 2-column grid lays out without scrolling.
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(child: AllwaysGamesApp()),
    );

    expect(find.text('Allways Games'), findsOneWidget);
    expect(find.text('Five'), findsOneWidget);
    expect(find.text('Sudoku'), findsOneWidget);
    expect(find.text('Crossword'), findsOneWidget);
    expect(find.text('Dot Dominoes'), findsOneWidget);
  });
}
