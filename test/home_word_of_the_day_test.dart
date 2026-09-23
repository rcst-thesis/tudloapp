import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_word_of_the_day.dart';

void main() {
  Widget wrap(bool isFavorited, ValueChanged<bool> onFavoriteChanged) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 378,
          child: HomeWordOfTheDay(
            isFavorited: isFavorited,
            onFavoriteChanged: onFavoriteChanged,
          ),
        ),
      ),
    );
  }

  testWidgets('Word of the Day reports the toggled value instead of flipping '
      'itself -- the caller (the real favorites set) owns isFavorited', (
    tester,
  ) async {
    final favoriteChanges = <bool>[];
    await tester.pumpWidget(wrap(false, favoriteChanges.add));

    final favorite = find.byKey(const Key('home-word-favorite-button'));
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

    await tester.tap(favorite);
    await tester.pump(const Duration(milliseconds: 200));
    expect(favoriteChanges, [true]);
    // Still unfavorited-looking: nothing updated `isFavorited` itself.
    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);

    // Simulate the caller applying the change (as HomeScreen would, once
    // persisted through the shared favorites set).
    await tester.pumpWidget(wrap(true, favoriteChanges.add));
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

    await tester.tap(favorite);
    await tester.pump(const Duration(milliseconds: 200));
    expect(favoriteChanges, [true, false]);
  });

  testWidgets('Word of the Day requests pronunciation through its callback', (
    tester,
  ) async {
    var pronunciationRequests = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 378,
            child: HomeWordOfTheDay(
              isFavorited: false,
              onPronunciationRequested: () async {
                pronunciationRequests++;
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('home-word-speaker-button')));
    await tester.pump();

    expect(pronunciationRequests, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Word of the Day scales a long word down within its card', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 378,
            child: HomeWordOfTheDay(
              word: 'pinakamasinadyahon',
              isFavorited: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text('pinakamasinadyahon'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('pinakamasinadyahon'),
        matching: find.byType(FittedBox),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
