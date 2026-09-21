import 'dart:io';

import 'package:dart_sentencepiece_tokenizer/dart_sentencepiece_tokenizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late SentencePieceTokenizer tokenizer;

  setUpAll(() {
    tokenizer = SentencePieceTokenizer.fromBytes(
      File('assets/models/tokenizer.model').readAsBytesSync(),
    );
  });

  test('NMT source tokens match the exported SentencePiece model', () {
    expect(
      [2, ...tokenizer.encode('hello', addSpecialTokens: false).ids, 3],
      [2, 5059, 118, 3],
    );
  });

  test('direction tags and word boundary are in the vocabulary', () {
    final vocab = tokenizer.getVocab();
    expect(vocab['<2source>'], 4);
    expect(vocab['<2target>'], 5);
    expect(vocab['▁'], 6665);

    // Same shape the training pipeline produced for "<2source> kumusta".
    expect(
      [
        vocab['▁']!,
        vocab['<2source>']!,
        ...tokenizer.encode('kumusta', addSpecialTokens: false).ids,
      ],
      [6665, 4, 5080, 198, 6666],
    );
  });
}
