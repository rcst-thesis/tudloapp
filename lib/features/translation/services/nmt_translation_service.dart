import 'dart:typed_data';

import 'package:dart_sentencepiece_tokenizer/dart_sentencepiece_tokenizer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_onnxruntime/flutter_onnxruntime.dart';

/// Bidirectional English <-> Hiligaynon model.
///
/// The model was trained with English as "source" and Hiligaynon as "target";
/// the direction is chosen by tagging the input with `<2target>` (to
/// Hiligaynon) or `<2source>` (to English), encoded exactly as the training
/// pipeline did: `[BOS, "▁", <tag>, ...text, EOS]`.
class NmtTranslationService {
  static const _modelAsset = 'assets/models/nmt_model.onnx';
  static const _tokenizerAsset = 'assets/models/tokenizer.model';
  static const _bosId = 2;
  static const _eosId = 3;
  static const _toHiligaynonTag = '<2target>';
  static const _toEnglishTag = '<2source>';
  static const _wordBoundary = '\u2581';
  static const _maxSourceLength = 128;
  static const _maxDecodeLength = 80;

  Future<_NmtResources>? _resources;
  Future<String>? _activeTranslation;
  bool _closed = false;

  /// Translates English to Hiligaynon.
  Future<String> translate(String text) => _run(text, toEnglish: false);

  /// Translates Hiligaynon to English.
  Future<String> translateToEnglish(String text) => _run(text, toEnglish: true);

  Future<String> _run(String text, {required bool toEnglish}) {
    if (_closed) throw StateError('Translation service is closed.');
    final translation = _translate(text, toEnglish: toEnglish);
    _activeTranslation = translation;
    return translation.whenComplete(() {
      if (identical(_activeTranslation, translation)) {
        _activeTranslation = null;
      }
    });
  }

  Future<String> _translate(String text, {required bool toEnglish}) async {
    final resources = await _getResources();
    var sourceIds = [
      _bosId,
      ...resources.directionPrefix(toEnglish: toEnglish),
      ...resources.tokenizer.encode(text, addSpecialTokens: false).ids,
      _eosId,
    ];
    if (sourceIds.length > _maxSourceLength) {
      sourceIds = sourceIds.sublist(0, _maxSourceLength);
      sourceIds[_maxSourceLength - 1] = _eosId;
    }

    final sourceTensor = await OrtValue.fromList(
      Int64List.fromList(sourceIds),
      [1, sourceIds.length],
    );
    final generated = <int>[_bosId];

    try {
      for (var step = 0; step < _maxDecodeLength; step++) {
        final targetTensor = await OrtValue.fromList(
          Int64List.fromList(generated),
          [1, generated.length],
        );
        Map<String, OrtValue> outputs = {};
        try {
          outputs = await resources.session.run({
            'src_tokens': sourceTensor,
            'tgt_tokens': targetTensor,
          });
          final values = await outputs['next_token']!.asFlattenedList();
          final nextToken = values.single as int;
          if (nextToken == _eosId) break;
          generated.add(nextToken);
        } finally {
          await targetTensor.dispose();
          for (final output in outputs.values) {
            await output.dispose();
          }
        }
      }
    } finally {
      await sourceTensor.dispose();
    }

    // Drop control/direction ids so a tag the model echoes never shows up.
    final tokens = generated
        .where((id) => !resources.controlIds.contains(id))
        .toList();
    return resources.tokenizer.decode(tokens).trim();
  }

  Future<_NmtResources> _getResources() async {
    final pending = _resources ??= _loadResources();
    try {
      return await pending;
    } catch (_) {
      if (identical(_resources, pending)) _resources = null;
      rethrow;
    }
  }

  Future<_NmtResources> _loadResources() async {
    final session = await OnnxRuntime().createSessionFromAsset(
      _modelAsset,
      options: OrtSessionOptions(
        intraOpNumThreads: 1,
        interOpNumThreads: 1,
        providers: [OrtProvider.CPU],
      ),
    );
    try {
      final data = await rootBundle.load(_tokenizerAsset);
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      final tokenizer = SentencePieceTokenizer.fromBytes(bytes);
      final vocab = tokenizer.getVocab();
      final toHiligaynon = vocab[_toHiligaynonTag];
      final toEnglish = vocab[_toEnglishTag];
      final boundary = vocab[_wordBoundary];
      if (toHiligaynon == null || toEnglish == null || boundary == null) {
        throw StateError('Tokenizer is missing the direction tokens.');
      }
      return _NmtResources(
        session: session,
        tokenizer: tokenizer,
        toHiligaynonPrefix: [boundary, toHiligaynon],
        toEnglishPrefix: [boundary, toEnglish],
        controlIds: {_bosId, _eosId, toHiligaynon, toEnglish},
      );
    } catch (_) {
      await session.close();
      rethrow;
    }
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    try {
      await _activeTranslation;
    } catch (_) {
      // A failed translation still needs its session closed.
    }
    final pending = _resources;
    if (pending == null) return;
    try {
      await (await pending).session.close();
    } catch (_) {
      // Initialization failed before a session became available.
    }
  }
}

class _NmtResources {
  final OrtSession session;
  final SentencePieceTokenizer tokenizer;
  final List<int> toHiligaynonPrefix;
  final List<int> toEnglishPrefix;
  final Set<int> controlIds;

  const _NmtResources({
    required this.session,
    required this.tokenizer,
    required this.toHiligaynonPrefix,
    required this.toEnglishPrefix,
    required this.controlIds,
  });

  List<int> directionPrefix({required bool toEnglish}) =>
      toEnglish ? toEnglishPrefix : toHiligaynonPrefix;
}
