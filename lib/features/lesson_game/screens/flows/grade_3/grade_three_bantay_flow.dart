import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tudloapp/core/services/app_audio_service.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/language_toggle.dart';
import 'package:tudloapp/core/widgets/mascot_widget.dart';
import 'package:tudloapp/features/lesson_game/widgets/reward_overlay.dart';

const _bantayRoot =
    'assets/images/level_game/grade3/G3_U2_L2.1_Ang_Nadula_nga_Ido_SVG_Assets';
const _bantayBackgroundRoot =
    'assets/images/level_game/backgrounds/grade3_landscape';
const _bantayEvents = ['missing', 'clue', 'found'];

enum _BantayStage {
  house,
  schoolMap,
  classroom,
  marketMap,
  market,
  farmMap,
  farm,
  found,
  model,
  sequence,
  reward,
}

class GradeThreeBantayFlow extends StatefulWidget {
  final VoidCallback onExit;
  final VoidCallback onLessonComplete;
  final VoidCallback onBackToMap;
  final VoidCallback onContinue;
  final String rewardStickerAsset;
  const GradeThreeBantayFlow({
    super.key,
    required this.onExit,
    required this.onLessonComplete,
    required this.onBackToMap,
    required this.onContinue,
    required this.rewardStickerAsset,
  });
  @override
  State<GradeThreeBantayFlow> createState() => _GradeThreeBantayFlowState();
}

class _GradeThreeBantayFlowState extends State<GradeThreeBantayFlow>
    with WidgetsBindingObserver {
  SharedPreferences? _storage;
  late String _saveKey;
  Future<void> _saveQueue = Future.value();
  _BantayStage _stage = _BantayStage.house;
  final Set<String> _searched = {};
  int _footprints = 0;
  bool _clue = false, _found = false, _collected = false;
  bool _ready = false, _busy = true;
  bool _sequenceValidated = false;
  final Set<int> _verifiedSlots = {};
  List<String?> _slots = List.filled(3, null);
  List<String> _trayOrder = [..._bantayEvents]..shuffle();
  String? _selected;
  Set<String> _wiggling = {};
  Set<String> _nudging = {};
  int _voiceGeneration = 0;
  Set<String> _voiceAssets = {};
  late final String _rewardStickerAsset = widget.rewardStickerAsset;
  bool get _sequenceCorrect =>
      _slots.indexed.every((e) => e.$2 == _bantayEvents[e.$1]);
  String get _location => switch (_stage) {
    _BantayStage.house => 'House',
    _BantayStage.schoolMap || _BantayStage.classroom => 'School',
    _BantayStage.marketMap || _BantayStage.market => 'Market',
    _ => 'Farm',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_storage == null && !_ready) {
      _ready = true;
      _saveKey =
          'bantay.g3.u2.l2.1.${AppStateScope.of(context).activeProfileId ?? 'guest'}';
      unawaited(_restore());
    }
  }

  Future<void> _restore() async {
    final storage = await SharedPreferences.getInstance();
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    if (!mounted) return;
    _storage = storage;
    _voiceAssets = manifest.listAssets().toSet();
    final raw = storage.getString(_saveKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _stage = _BantayStage.values.firstWhere(
          (s) => s.name == data['currentStage'],
          orElse: () => _BantayStage.house,
        );
        _searched.addAll(List<String>.from(data['searchedHotspotIds'] ?? []));
        _footprints = ((data['footprintIndex'] as int?) ?? 0).clamp(0, 3);
        _clue = data['farmClueCollected'] == true;
        _found = data['bantayFound'] == true;
        _collected = data['storyDetectiveCollected'] == true;
        _sequenceValidated = data['sequenceCompleted'] == true;
        _verifiedSlots.addAll(
          List<int>.from(data['correctSequenceSlotIds'] ?? []),
        );
        final order = List<String?>.from(
          data['sequenceOrder'] ?? [null, null, null],
        );
        if (order.length == 3) _slots = order;
        final tray = List<String>.from(data['trayOrder'] ?? []);
        if (tray.length == 3 && tray.toSet().containsAll(_bantayEvents)) {
          _trayOrder = tray;
        }
      } on FormatException {
        /* Keep the fresh activity when a save is unreadable. */
      }
    }
    if (_stage == _BantayStage.farm && _footprints == 3) {
      _found = true;
      _stage = _BantayStage.found;
      await _save();
      if (!mounted) return;
    }
    setState(() {});
    if (_collected) widget.onLessonComplete();
    await _voiceForStage();
  }

  Future<void> _save() {
    final storage = _storage;
    if (storage == null) return Future.value();
    final complete = [
      'House',
      if (_searched.length == 3) 'School',
      if (_clue) 'Market',
      if (_found) 'Farm',
    ];
    final snapshot = jsonEncode({
      'currentStage': _stage.name,
      'currentLocation': _location,
      'unlockedLocationIds': [
        'House',
        if (_stage != _BantayStage.house) 'School',
        if (_searched.length == 3) 'Market',
        if (_clue) 'Farm',
      ],
      'completedLocationIds': complete,
      'searchedHotspotIds': _searched.toList(),
      'classroomSearchCount': _searched.length,
      'farmClueCollected': _clue,
      'footprintIndex': _footprints,
      'completedFootprintIds': List.generate(
        _footprints,
        (i) => 'footprint_${i + 1}',
      ),
      'bantayFound': _found,
      'sequenceOrder': _slots,
      'correctSequenceSlotIds': _verifiedSlots.toList(),
      'sequenceCompleted': _sequenceValidated,
      'storyDetectiveCollected': _collected,
      'lessonCompleted': _collected,
      'trayOrder': _trayOrder,
      'farmReplayUnlocked': _collected,
      'investigationReplayUnlocked': _collected,
    });
    _saveQueue = _saveQueue.then((_) async {
      await storage.setString(_saveKey, snapshot);
    });
    return _saveQueue;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      unawaited(_save());
      _voiceGeneration++;
      unawaited(TudloVoiceButton.stop());
      unawaited(AppAudioService.instance.stopVoice());
    } else if (mounted) {
      unawaited(_voiceForStage());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _voiceGeneration++;
    unawaited(_save());
    unawaited(TudloVoiceButton.stop());
    unawaited(AppAudioService.instance.stopVoice());
    super.dispose();
  }

  // Semantic clip keys avoid assigning a numbered recording to the wrong line.
  Future<void> _line(String key, String text) async {
    if (!AppAudioService.instance.voiceOverEnabled) return;
    final candidates = [
      'assets/audio/VO-final/grade3/G3U2L2_1_$key.wav',
      'assets/audio/VO-final/grade3/G3U2L2_1_$key.WAV',
    ];
    final asset = candidates.where(_voiceAssets.contains).firstOrNull;
    if (asset != null) {
      await AppAudioService.instance.playVoiceAssets([asset.substring(7)]);
    } else if (mounted) {
      await TudloVoiceButton.speak(context, text, hiligaynon: true);
    }
  }

  Future<void> _speak(List<(String, String)> lines) async {
    if (!mounted) return;
    if (!AppAudioService.instance.voiceOverEnabled) {
      setState(() => _busy = false);
      return;
    }
    final generation = ++_voiceGeneration;
    setState(() => _busy = true);
    await TudloVoiceButton.stop();
    await AppAudioService.instance.stopVoice();
    await AppAudioService.instance.lowerBackgroundVolume();
    try {
      for (final line in lines) {
        if (!mounted || generation != _voiceGeneration) return;
        await _line(line.$1, line.$2);
      }
    } finally {
      await AppAudioService.instance.restoreBackgroundVolume();
      if (mounted && generation == _voiceGeneration) {
        setState(() => _busy = false);
      }
    }
  }

  List<(String, String)> _stageVoiceLines() => switch (_stage) {
    _BantayStage.house => [
      ('S01_D', 'Abyan, wala diri si Bantay! Buligan mo ako pangita sa iya?'),
      ('S01_I', 'I-tap ang Pangitaon ta para magsugod.'),
    ],
    _BantayStage.schoolMap => [
      ('S02_D', 'I-tap ang School. Basi ara siya sa classroom.'),
      (
        'S02_I',
        'I-tap ang School sa mapa kag usisaon ang tatlo ka lugar sa classroom.',
      ),
    ],
    _BantayStage.marketMap => [
      ('S03_D', 'Pamangkuton ta ang tindera.'),
      ('S03_I', 'I-tap ang Market sa mapa, dayon i-tap ang tindera.'),
    ],
    _BantayStage.farmMap => [
      ('S04_D', 'May footprints! Sunda naton sila.'),
      ('S04_I', 'I-tap ang Farm kag sundon ang tatlo ka footprints.'),
    ],
    _BantayStage.found => [('S06_D', 'Salamat! Nakita naton si Bantay!')],
    _BantayStage.model => [('S05_D', 'Ano ang una, sunod, kag katapusan?')],
    _BantayStage.sequence => [
      ('S05_I', 'Ihan-ay ang nadula, clue, kag nakita.'),
    ],
    _BantayStage.reward => [('S06_I', 'I-tap ang Story Detective sticker.')],
    _BantayStage.market =>
      _clue
          ? [('VENDOR', 'Tan-awa sa uma!')]
          : [('S03_I', 'I-tap ang Market sa mapa, dayon i-tap ang tindera.')],
    _BantayStage.classroom => [
      (
        'S02_I',
        'I-tap ang School sa mapa kag usisaon ang tatlo ka lugar sa classroom.',
      ),
    ],
    _BantayStage.farm => [
      ('S04_I', 'I-tap ang Farm kag sundon ang tatlo ka footprints.'),
    ],
  };

  Future<void> _voiceForStage() => _speak(_stageVoiceLines());

  Future<void> _replayInstruction() async {
    final lines = _stageVoiceLines();
    if (lines.isEmpty) return;
    await _speak([lines.last]);
  }

  Future<void> _nudge(String id) async {
    if (_nudging.contains(id)) return;
    setState(() => _nudging = {..._nudging, id});
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    setState(() {
      _nudging = {..._nudging}..remove(id);
    });
  }

  Future<void> _go(_BantayStage next) async {
    if (_busy || _storage == null) return;
    if (next == _BantayStage.marketMap && _searched.length != 3) return;
    if (next == _BantayStage.farmMap && !_clue) return;
    if (next == _BantayStage.reward && !_sequenceValidated) return;
    setState(() {
      _stage = next;
      _selected = null;
      _busy = true;
    });
    await _save();
    if (mounted) await _voiceForStage();
  }

  Future<void> _search(String id) async {
    if (_busy) return;
    if (_searched.contains(id)) {
      await _nudge(id);
      return;
    }
    setState(() {
      _busy = true;
      _searched.add(id);
    });
    await _save();
    await AppAudioService.instance.playCorrect();
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _vendor() async {
    if (_busy || _clue) return;
    await _speak([('S03_D', 'Pamangkuton ta ang tindera.')]);
    if (!mounted) return;
    setState(() {
      _busy = true;
      _selected = 'vendor';
    });
    await _speak([('VENDOR', 'Tan-awa sa uma!')]);
    if (!mounted) return;
    setState(() {
      _busy = true;
      _clue = true;
    });
    await _save();
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (mounted) {
      setState(() {
        _busy = false;
        _selected = null;
      });
    }
  }

  Future<void> _footprint(int index) async {
    if (_busy) return;
    if (index != _footprints) {
      await _nudge('footprint_$index');
      return;
    }
    setState(() {
      _busy = true;
      _footprints++;
    });
    await _save();
    await AppAudioService.instance.playCorrect();
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    if (_footprints == 3) {
      setState(() {
        _found = true;
        _stage = _BantayStage.found;
      });
      await _save();
      await _voiceForStage();
    } else {
      setState(() => _busy = false);
    }
  }

  Future<void> _place(String id, int index) async {
    if (_busy ||
        !_bantayEvents.contains(id) ||
        _slots.contains(id) ||
        _slots[index] != null) {
      return;
    }
    setState(() {
      _slots[index] = id;
      _selected = null;
    });
    await _save();
  }

  Future<void> _checkSequence() async {
    if (_busy || _slots.contains(null)) return;
    final misplaced = _slots.indexed
        .where((e) => e.$2 != _bantayEvents[e.$1])
        .map((e) => e.$2!)
        .toSet();
    _verifiedSlots.addAll(
      _slots.indexed.where((e) => e.$2 == _bantayEvents[e.$1]).map((e) => e.$1),
    );
    if (misplaced.isEmpty) {
      setState(() {
        _busy = true;
        _sequenceValidated = true;
      });
      await _save();
      await AppAudioService.instance.playCorrect();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() => _busy = false);
    } else {
      setState(() {
        _busy = true;
        _wiggling = misplaced;
      });
      await _speak([('RETRY', 'Hmmm, hindi amo na.')]);
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < 3; i++) {
          if (misplaced.contains(_slots[i])) _slots[i] = null;
        }
        _wiggling = {};
        _busy = false;
      });
      await _save();
    }
  }

  Future<void> _collect() async {
    if (_busy || _collected) return;
    setState(() {
      _busy = true;
      _collected = true;
    });
    final profileId = AppStateScope.of(context).activeProfileId ?? 'guest';
    await _save();
    final inventoryKey = 'lesson.reward.inventory.$profileId';
    final inventory =
        _storage!.getStringList(inventoryKey)?.toSet() ?? <String>{};
    inventory.add(_rewardStickerAsset);
    await _storage!.setStringList(inventoryKey, inventory.toList());
    if (!mounted) return;
    widget.onLessonComplete();
    await AppAudioService.instance.playStar();
    if (mounted) setState(() => _busy = false);
  }

  Widget _asset(String path) =>
      SvgPicture.asset('$_bantayRoot/$path', fit: BoxFit.contain);
  Widget _at(double x, double y, double w, double h, Widget child) =>
      Positioned(left: x, top: y, width: w, height: h, child: child);
  Widget _text(String text, {double size = 25}) => Center(
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Baloo2',
        fontSize: size,
        height: 1.1,
        fontWeight: FontWeight.w800,
        color: TudloColors.ink,
      ),
    ),
  );
  Widget _panel(Widget child, {bool correct = false}) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: correct ? Colors.green : Colors.lightBlue,
        width: 3,
      ),
    ),
    child: child,
  );
  Widget _button(String label, VoidCallback action) => ElevatedButton(
    onPressed: _busy ? null : action,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.lightBlue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontFamily: 'Baloo2',
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
  Widget _next(_BantayStage next) =>
      _at(660, 442, 260, sixty, _button('SUNOD', () => unawaited(_go(next))));
  static const double sixty = 60;

  Widget _event(String id, {bool correct = false}) {
    final image = switch (id) {
      'missing' => 'props/Dog_Bed_Empty.svg',
      'clue' => 'people/Vendor_Female_Pointing.svg',
      _ => 'animals/Bantay_Idle.svg',
    };
    return _panel(
      Column(
        children: [
          Text(
            switch (id) {
              'missing' => 'NADULA',
              'clue' => 'CLUE',
              _ => 'NAKITA',
            },
            style: const TextStyle(
              fontFamily: 'Baloo2',
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                if (id != 'clue')
                  Positioned.fill(
                    child: SvgPicture.asset(
                      '$_bantayBackgroundRoot/${id == 'missing' ? 'HospitalLandscape-1 1.svg' : 'FarmLandscape 1.svg'}',
                      fit: BoxFit.cover,
                    ),
                  ),
                Positioned.fill(child: _asset(image)),
                if (id == 'clue')
                  Positioned(
                    right: 0,
                    bottom: 0,
                    width: 65,
                    height: 65,
                    child: _asset('clues/Farm_Clue_Card.svg'),
                  ),
                if (id == 'missing')
                  Positioned(
                    right: 0,
                    bottom: 0,
                    width: 60,
                    height: 40,
                    child: _asset('props/Dog_Bowl.svg'),
                  ),
              ],
            ),
          ),
        ],
      ),
      correct: correct,
    );
  }

  Widget _hotspot(
    String id,
    String label,
    double x,
    double y,
    double w,
    double h,
  ) => _at(
    x,
    y,
    w,
    h,
    _BantayPulse(
      active: !_searched.contains(id) || _nudging.contains(id),
      wiggle: _nudging.contains(id),
      child: GestureDetector(
        onTap: () => unawaited(_search(id)),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _searched.contains(id)
                  ? Colors.green
                  : const Color(0xFFFFD447),
              width: 3,
            ),
          ),
          child: Column(
            children: [
              _panel(_text(label, size: 22)),
              const Spacer(),
              if (_searched.contains(id))
                const Icon(Icons.check_circle, color: Colors.green, size: 48),
            ],
          ),
        ),
      ),
    ),
  );

  List<Widget> _scene() {
    final map = [
      _BantayStage.schoolMap,
      _BantayStage.marketMap,
      _BantayStage.farmMap,
    ].contains(_stage);
    if (map) {
      final active = _location;
      const names = ['House', 'School', 'Market', 'Farm'];
      return [
        _at(200, 86, 560, sixty, _panel(_text('I-tap ang $active.'))),
        for (final entry in names.indexed)
          _at(
            160 + entry.$1 * 186,
            175,
            170,
            230,
            _BantayPulse(
              active:
                  entry.$2 == active || _nudging.contains('map_${entry.$2}'),
              wiggle: _nudging.contains('map_${entry.$2}'),
              child: GestureDetector(
                onTap: () {
                  if (_busy) return;
                  if (entry.$2 == active) {
                    unawaited(
                      _go(switch (active) {
                        'School' => _BantayStage.classroom,
                        'Market' => _BantayStage.market,
                        _ => _BantayStage.farm,
                      }),
                    );
                  } else {
                    unawaited(_nudge('map_${entry.$2}'));
                  }
                },
                child: _panel(
                  Column(
                    children: [
                      _text(entry.$2.toUpperCase(), size: 22),
                      Expanded(
                        child: _asset('map/${entry.$2}_Location_Icon.svg'),
                      ),
                      Icon(
                        entry.$2 == active
                            ? Icons.touch_app
                            : (entry.$1 < names.indexOf(active)
                                  ? Icons.check_circle
                                  : Icons.lock),
                        color: entry.$1 <= names.indexOf(active)
                            ? Colors.green
                            : Colors.grey,
                        size: 44,
                      ),
                    ],
                  ),
                  correct: entry.$2 == active,
                ),
              ),
            ),
          ),
      ];
    }
    return switch (_stage) {
      _BantayStage.house => [
        _at(
          285,
          96,
          580,
          100,
          _panel(
            _text(
              'Abyan, wala diri si Bantay!\nBuligan mo ako pangita sa iya?',
            ),
          ),
        ),
        _at(330, 285, 300, 120, _asset('props/Dog_Bed_Empty.svg')),
        _at(640, 328, 110, 80, _asset('props/Dog_Bowl.svg')),
        _at(
          490,
          442,
          390,
          sixty,
          _button('PANGITAON TA', () => unawaited(_go(_BantayStage.schoolMap))),
        ),
      ],
      _BantayStage.classroom => [
        _at(
          250,
          85,
          600,
          70,
          _panel(
            _text(
              _searched.length == 3
                  ? 'Wala siya diri. Pamangkuton ta ang tindera.'
                  : 'Pangitaa si Bantay - ${_searched.length}/3',
            ),
          ),
        ),
        _hotspot('classroom_desk', 'Lamesa', 270, 265, 185, 140),
        _hotspot('classroom_bag', 'Bag', 500, 280, 140, 140),
        _hotspot('classroom_door', 'Pultahan', 770, 195, 155, 215),
        if (_searched.length == 3) _next(_BantayStage.marketMap),
      ],
      _BantayStage.market => [
        _at(
          280,
          90,
          550,
          70,
          _panel(
            _text(
              _clue || _selected == 'vendor'
                  ? 'Tan-awa sa uma!'
                  : 'I-tap ang tindera.',
            ),
          ),
        ),
        _at(
          570,
          180,
          285,
          235,
          _BantayPulse(
            active: !_clue,
            child: GestureDetector(
              onTap: () => unawaited(_vendor()),
              child: _asset(
                'people/Vendor_Female_${_clue || _selected == 'vendor' ? 'Pointing' : 'Idle'}.svg',
              ),
            ),
          ),
        ),
        if (_clue)
          _at(
            300,
            305,
            180,
            135,
            AnimatedScale(
              scale: _clue ? 1 : .5,
              duration: const Duration(milliseconds: 450),
              child: _panel(_asset('clues/Farm_Clue_Card.svg'), correct: true),
            ),
          ),
        if (_clue) _next(_BantayStage.farmMap),
      ],
      _BantayStage.farm => [
        _at(
          260,
          90,
          570,
          70,
          _panel(_text('Sunda ang footprints - $_footprints/3')),
        ),
        for (var i = 0; i < 3; i++)
          _at(
            310 + i * 185,
            335 - i * 18,
            125,
            115,
            _BantayPulse(
              active: i == _footprints || _nudging.contains('footprint_$i'),
              wiggle: _nudging.contains('footprint_$i'),
              child: GestureDetector(
                onTap: () => unawaited(_footprint(i)),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: i <= _footprints ? 1 : .35,
                        child: _asset('clues/Dog_Footprint.svg'),
                      ),
                    ),
                    if (i < _footprints)
                      const Align(
                        alignment: Alignment.bottomRight,
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: forty,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
      _BantayStage.found => [
        _at(
          280,
          90,
          550,
          85,
          _panel(_text('Salamat! Nakita naton si Bantay!')),
        ),
        _at(
          610,
          215,
          235,
          205,
          _BantayPulse(active: true, child: _asset('animals/Bantay_Happy.svg')),
        ),
        _next(_BantayStage.model),
      ],
      _BantayStage.model => [
        _at(
          200,
          90,
          680,
          70,
          _panel(_text('Ano ang una, sunod, kag katapusan?')),
        ),
        for (final entry in _trayOrder.indexed)
          _at(245 + entry.$1 * 205, 190, 185, 225, _event(entry.$2)),
        _next(_BantayStage.sequence),
      ],
      _BantayStage.sequence => [
        _at(
          185,
          82,
          735,
          sixty,
          _panel(_text('Ihan-ay ang nadula, clue, kag nakita.')),
        ),
        for (var i = 0; i < 3; i++)
          _at(
            225 + i * 220,
            155,
            205,
            160,
            DragTarget<String>(
              onWillAcceptWithDetails: (d) =>
                  !_busy && _slots[i] == null && !_slots.contains(d.data),
              onAcceptWithDetails: (d) => unawaited(_place(d.data, i)),
              builder: (context, candidates, rejected) => GestureDetector(
                onTap: () {
                  if (_selected != null) unawaited(_place(_selected!, i));
                },
                child: Column(
                  children: [
                    _text(['UNA', 'SUNOD', 'KATAPUSAN'][i], size: 20),
                    Expanded(
                      child: _slots[i] == null
                          ? _panel(const SizedBox.expand())
                          : _BantayPulse(
                              active: _wiggling.contains(_slots[i]),
                              wiggle: true,
                              child: _event(
                                _slots[i]!,
                                correct: _verifiedSlots.contains(i),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        for (final entry in _trayOrder.indexed)
          if (!_slots.contains(entry.$2))
            _at(
              225 + entry.$1 * 220,
              332,
              205,
              130,
              Draggable<String>(
                data: entry.$2,
                maxSimultaneousDrags: _busy ? 0 : 1,
                feedback: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: 180,
                    height: 130,
                    child: _event(entry.$2),
                  ),
                ),
                childWhenDragging: const SizedBox.expand(),
                child: GestureDetector(
                  onTap: () {
                    if (!_busy) setState(() => _selected = entry.$2);
                  },
                  child: _BantayPulse(
                    active: _selected == entry.$2,
                    child: _event(entry.$2),
                  ),
                ),
              ),
            ),
        if (_sequenceValidated && _sequenceCorrect)
          _at(
            660,
            474,
            260,
            48,
            _button('SUNOD', () => unawaited(_go(_BantayStage.reward))),
          )
        else if (!_slots.contains(null))
          _at(
            660,
            474,
            260,
            48,
            _button('USISAON', () => unawaited(_checkSequence())),
          ),
      ],
      _BantayStage.reward => [
        Positioned.fill(
          child: GradeThreeStickerRewardOverlay(
            stickerAsset: _rewardStickerAsset,
            message: 'Maayo gid!\nNatapos mo ang Ang Nadula nga Ido.',
            primaryLabel: 'PADAYUN KITA',
            onPrimary: () async {
              await _collect();
              if (!mounted) return;
              widget.onContinue();
            },
            secondaryLabel: 'MAG BALIK SA MAPA',
            onSecondary: () async {
              await _collect();
              if (!mounted) return;
              widget.onBackToMap();
            },
          ),
        ),
      ],
      _ => [],
    };
  }

  static const double forty = 40;

  @override
  Widget build(BuildContext context) {
    final background = switch (_location) {
      'House' => 'HospitalLandscape-1 1.svg',
      'School' => 'ClassroomLandscape 1.svg',
      'Market' => 'MarketLandscape 1.svg',
      _ => 'FarmLandscape 1.svg',
    };
    final isMap = [
      _BantayStage.schoolMap,
      _BantayStage.marketMap,
      _BantayStage.farmMap,
    ].contains(_stage);
    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        child: Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 960,
                height: 540,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: SvgPicture.asset(
                        isMap
                            ? 'assets/images/level_game/backgrounds/tudlomap.svg'
                            : '$_bantayBackgroundRoot/$background',
                        fit: BoxFit.cover,
                      ),
                    ),
                    _at(
                      24,
                      200,
                      195,
                      300,
                      TudloMascot(
                        size: 300,
                        mood: _busy
                            ? KokaMood.talking
                            : (_found ? KokaMood.idle : KokaMood.curious),
                      ),
                    ),
                    ..._scene(),
                    _at(
                      24,
                      24,
                      58,
                      58,
                      IconButton.filled(
                        onPressed: () async {
                          await _save();
                          if (mounted) widget.onExit();
                        },
                        icon: const Icon(Icons.arrow_back, size: 36),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.lightBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    _at(
                      320,
                      thirty,
                      320,
                      24,
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value:
                              (_stage.index + 1) / _BantayStage.values.length,
                          color: Colors.lightGreenAccent,
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                    _at(
                      878,
                      24,
                      58,
                      58,
                      IconButton.filled(
                        onPressed: _busy
                            ? null
                            : () => unawaited(_replayInstruction()),
                        icon: const Icon(Icons.volume_up, size: 34),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const double thirty = 30;
}

class _BantayPulse extends StatefulWidget {
  final bool active;
  final bool wiggle;
  final Widget child;
  const _BantayPulse({
    required this.active,
    this.wiggle = false,
    required this.child,
  });
  @override
  State<_BantayPulse> createState() => _BantayPulseState();
}

class _BantayPulseState extends State<_BantayPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );
  @override
  void initState() {
    super.initState();
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_BantayPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) => Transform.translate(
      offset: Offset(
        widget.wiggle && widget.active
            ? math.sin(_controller.value * math.pi * 6) * 6
            : 0,
        0,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: widget.active && !widget.wiggle
              ? [
                  BoxShadow(
                    color: const Color(
                      0xFFFFD447,
                    ).withValues(alpha: .2 + _controller.value * .25),
                    blurRadius: 24,
                    spreadRadius: 7,
                  ),
                ]
              : [],
        ),
        child: child,
      ),
    ),
    child: widget.child,
  );
}
