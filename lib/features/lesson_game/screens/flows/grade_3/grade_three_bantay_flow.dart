import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tudloapp/core/navigation/fade_page_route.dart';
import 'package:tudloapp/core/services/app_audio_service.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/animated_point_finger.dart';
import 'package:tudloapp/core/widgets/language_toggle.dart';
import 'package:tudloapp/core/widgets/mascot_widget.dart';
import 'package:tudloapp/features/lesson_game/screens/flows/grade_3/grade_three_pressable.dart';
import 'package:tudloapp/features/lesson_game/widgets/reward_overlay.dart';
import 'package:tudloapp/features/map/domain/map_location.dart' as tudlo_map;
import 'package:tudloapp/features/map/domain/map_route_resolver.dart'
    as tudlo_map;
import 'package:tudloapp/features/map/presentation/screens/map_screen.dart'
    as tudlo_map;

const _bantayRoot =
    'assets/images/level_game/grade3/G3_U2_L2.1_Ang_Nadula_nga_Ido_SVG_Assets';
const _bantayUpdatedRoot = '$_bantayRoot/updated';
const _bantayBackgroundRoot =
    'assets/images/level_game/backgrounds/grade3_landscape';
const _bantayPointFinger =
    'assets/images/level_game/lesson-game-assets/point-finger.png';
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
  final List<String> _trayOrder = const ['found', 'clue', 'missing'];
  String? _selected;
  String? _activeMarketDialogueClip;
  Set<String> _wiggling = {};
  Set<String> _nudging = {};
  final Set<_BantayStage> _openedMapStages = {};
  int _voiceGeneration = 0;
  Set<String> _voiceAssets = {};
  late final String _rewardStickerAsset = widget.rewardStickerAsset;
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
        if (_searched.remove('classroom_bag')) {
          _searched.add('classroom_window');
        }
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
    if (mounted) await _openMapForStage(_stage);
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
    final numbered = int.tryParse(key) != null;
    final candidates = numbered
        ? [
            'assets/audio/VO-final/grade3/Gr_3_Les_2_1_$key.wav',
            'assets/audio/VO-final/grade3/Gr_3_Les_2_1_$key.WAV',
          ]
        : [
            'assets/audio/VO-final/grade3/G3U2L2_1_$key.wav',
            'assets/audio/VO-final/grade3/G3U2L2_1_$key.WAV',
          ];
    final asset = candidates.where(_voiceAssets.contains).firstOrNull;
    if (asset != null) {
      await AppAudioService.instance.playVoiceAssets([asset.substring(7)]);
    } else if (numbered) {
      return;
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
        final marketDialogueClip = _marketDialogueText(line.$1) == null
            ? null
            : line.$1;
        if (_activeMarketDialogueClip != marketDialogueClip && mounted) {
          setState(() => _activeMarketDialogueClip = marketDialogueClip);
        }
        await _line(line.$1, line.$2);
        if (mounted &&
            generation == _voiceGeneration &&
            _activeMarketDialogueClip == marketDialogueClip) {
          setState(() => _activeMarketDialogueClip = null);
        }
      }
    } finally {
      await AppAudioService.instance.restoreBackgroundVolume();
      if (mounted && generation == _voiceGeneration) {
        setState(() {
          _activeMarketDialogueClip = null;
          _busy = false;
        });
      }
    }
  }

  String? _marketDialogueText(String clip) => switch (clip) {
    '13' => 'Maayong Adlaw! May nakita ka bala nga ido nga nagalaw diri?',
    '14' => 'Huo, may nakita ako nga ido nga nagadalan pakadto sa uma.',
    '15' => 'Tan-awa ang mga marka lapit sa dalan.',
    '16' => 'Salamat!',
    _ => null,
  };

  List<(String, String)> _stageVoiceLines() => switch (_stage) {
    _BantayStage.house => [('2', '')],
    _BantayStage.schoolMap => [('3', '')],
    _BantayStage.marketMap => [('10', '')],
    _BantayStage.farmMap => [('19', '')],
    _BantayStage.found => [('26', ''), ('27', '')],
    _BantayStage.model => [('28', ''), ('29', '')],
    _BantayStage.sequence => [('30', '')],
    _BantayStage.reward => [('34', '')],
    _BantayStage.market => _clue ? [('17', '')] : [('11', ''), ('12', '')],
    _BantayStage.classroom => [('4', ''), ('5', '')],
    _BantayStage.farm => [('20', ''), ('21', '')],
  };

  Future<void> _voiceForStage() async {
    final stage = _stage;
    await _speak(_stageVoiceLines());
    if (!mounted || _stage != stage) return;
    if (stage != _BantayStage.found && stage != _BantayStage.model) return;
    setState(() => _busy = false);
    await _go(
      stage == _BantayStage.found ? _BantayStage.model : _BantayStage.sequence,
    );
  }

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
    if (mounted) {
      await _voiceForStage();
      if (mounted) await _openMapForStage(next);
    }
  }

  bool _isMapStage(_BantayStage stage) =>
      stage == _BantayStage.schoolMap ||
      stage == _BantayStage.marketMap ||
      stage == _BantayStage.farmMap;

  tudlo_map.MapLocation _mapLocationForStage(_BantayStage stage) =>
      switch (stage) {
        _BantayStage.schoolMap => tudlo_map.MapLocation.school,
        _BantayStage.marketMap => tudlo_map.MapLocation.market,
        _BantayStage.farmMap => tudlo_map.MapLocation.farm,
        _ => tudlo_map.MapLocation.house,
      };

  _BantayStage _lessonStageAfterMap(_BantayStage stage) => switch (stage) {
    _BantayStage.schoolMap => _BantayStage.classroom,
    _BantayStage.marketMap => _BantayStage.market,
    _BantayStage.farmMap => _BantayStage.farm,
    _ => stage,
  };

  String _mapInstructionForStage(_BantayStage stage) => switch (stage) {
    _BantayStage.schoolMap => 'I-tap ang School sa mapa.',
    _BantayStage.marketMap => 'I-tap ang Market sa mapa.',
    _BantayStage.farmMap => 'I-tap ang Farm sa mapa.',
    _ => 'I-tap ang lugar sa mapa.',
  };

  Future<void> _openMapForStage(_BantayStage stage) async {
    if (!_isMapStage(stage) ||
        _openedMapStages.contains(stage) ||
        !mounted ||
        _stage != stage) {
      return;
    }
    _openedMapStages.add(stage);
    await _showGradeThreeMapInstructionDialog(
      context,
      message: _mapInstructionForStage(stage),
    );
    if (!mounted || _stage != stage) return;
    final location = _mapLocationForStage(stage);
    final overrides = tudlo_map.MapEventOverrides()
      ..setOverride(location, const tudlo_map.PopMapRouteAction());
    await Navigator.of(context).push(
      FadePageRoute<void>(
        page: tudlo_map.MapScreen(
          eventOverrides: overrides,
          temporaryUnlockedLocations: {location},
          initialFocusLocation: location,
        ),
      ),
    );
    if (!mounted || _stage != stage) return;
    await AppAudioService.instance.playCorrect();
    setState(() {
      _stage = _lessonStageAfterMap(stage);
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
    if (id == 'classroom_door' &&
        !(_searched.contains('classroom_desk') &&
            _searched.contains('classroom_window'))) {
      await _speak([('8', '')]);
      await _nudge(id);
      return;
    }
    setState(() {
      _busy = true;
      _searched.add(id);
    });
    await _save();
    await AppAudioService.instance.playCorrect();
    if (_stage == _BantayStage.classroom) {
      final clips = switch (id) {
        'classroom_desk' => const [('6', '')],
        'classroom_window' => const [('7', '')],
        'classroom_door' => const [('8', '')],
        _ => const <(String, String)>[],
      };
      if (clips.isNotEmpty) await _speak(clips);
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted && id == 'classroom_door') {
      setState(() => _busy = false);
      await _go(_BantayStage.marketMap);
      return;
    }
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _vendor() async {
    if (_busy || _clue) return;
    setState(() {
      _busy = true;
      _selected = 'koka_hi';
    });
    await _speak([('13', '')]);
    if (!mounted) return;
    setState(() {
      _busy = true;
      _selected = 'vendor_reply';
    });
    await _speak([('14', '')]);
    if (!mounted) return;
    setState(() {
      _busy = true;
      _selected = 'vendor';
    });
    await _speak([('15', ''), ('16', ''), ('17', '')]);
    if (!mounted) return;
    setState(() {
      _busy = true;
      _clue = true;
    });
    await _save();
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (mounted) {
      setState(() => _busy = false);
      await _go(_BantayStage.farmMap);
    }
  }

  Future<void> _marketOutsideTap() async {
    if (_busy || _clue || _stage != _BantayStage.market) return;
    await _speak([('18', '')]);
  }

  Future<void> _footprint(int index) async {
    if (_busy) return;
    if (index != _footprints) {
      await _speak([('25', '')]);
      await _nudge('footprint_$index');
      return;
    }
    final nextCount = _footprints + 1;
    setState(() {
      _busy = true;
      _footprints = nextCount;
    });
    await _save();
    await AppAudioService.instance.playCorrect();
    await _speak([
      (
        switch (nextCount) {
          1 => '22',
          2 => '23',
          _ => '24',
        },
        '',
      ),
    ]);
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

  Future<void> _wrongFootprintTap() async {
    if (_busy || _stage != _BantayStage.farm) return;
    await _speak([('25', '')]);
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
    if (!_slots.contains(null)) {
      if (mounted) await _checkSequence();
    }
  }

  Future<void> _checkSequence() async {
    if (_busy || _slots.contains(null)) return;
    final misplaced = _slots.indexed
        .where((e) => e.$2 != _bantayEvents[e.$1])
        .map((e) => e.$2!)
        .toSet();
    _verifiedSlots
      ..clear()
      ..addAll(
        _slots.indexed
            .where((e) => e.$2 == _bantayEvents[e.$1])
            .map((e) => e.$1),
      );
    if (misplaced.isEmpty) {
      setState(() {
        _busy = true;
        _sequenceValidated = true;
      });
      await _save();
      await _speak([('31', ''), ('32', '')]);
      if (!mounted) return;
      await AppAudioService.instance.playCorrect();
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        setState(() => _busy = false);
        await _go(_BantayStage.reward);
      }
    } else {
      setState(() {
        _busy = true;
        _wiggling = misplaced;
      });
      await _speak([('33', '')]);
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < 3; i++) {
          if (misplaced.contains(_slots[i])) _slots[i] = null;
        }
        _wiggling = {};
        _verifiedSlots.clear();
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

  Widget _asset(String path) {
    final asset = path.startsWith('updated/')
        ? '$_bantayUpdatedRoot/${path.substring('updated/'.length)}'
        : '$_bantayRoot/$path';
    if (asset.toLowerCase().endsWith('.png')) {
      return Image.asset(asset, fit: BoxFit.contain);
    }
    return SvgPicture.asset(asset, fit: BoxFit.contain);
  }

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

  Widget _prompt(String text) => _at(
    96,
    56,
    768,
    64,
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFAE7).withValues(alpha: .96),
        borderRadius: BorderRadius.circular(26),
      ),
      child: _text(text, size: 25),
    ),
  );

  Widget _button(String label, VoidCallback action) => GradeThreePressable(
    enabled: !_busy,
    onTap: _busy ? null : action,
    borderRadius: 18,
    child: Opacity(
      opacity: _busy ? .65 : 1,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFF1BA7F2),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white, width: 4),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Baloo2',
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    ),
  );

  Widget _bottomAction(String label, VoidCallback action) =>
      _at(156, 458, 648, 64, _button(label, action));

  Widget _event(String id, {bool correct = false, bool framed = true}) {
    final image = switch (id) {
      'missing' => 'updated/NADULA_Card.png',
      'clue' => 'updated/CLUE_Card.png',
      _ => 'updated/NAKITA_Card.png',
    };
    if (!framed) return _asset(image);
    return _panel(_asset(image), correct: correct);
  }

  Widget _grayEvent(String id) => Opacity(
    opacity: .72,
    child: ColorFiltered(
      colorFilter: const ColorFilter.mode(Color(0xFFA8A8A8), BlendMode.srcIn),
      child: _event(id, framed: false),
    ),
  );

  Widget _hotspot(
    String id,
    String label,
    double x,
    double y,
    double w,
    double h,
  ) {
    final searched = _searched.contains(id);
    return _at(
      x,
      y + 16,
      w,
      h,
      _BantayPulse(
        active: false,
        wiggle: _nudging.contains(id),
        child: GestureDetector(
          onTap: () => unawaited(_search(id)),
          child: Container(
            padding: const EdgeInsets.all(8),
            color: Colors.transparent,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: searched
                          ? const Color.fromARGB(255, 255, 0, 0)
                          : Colors.white.withValues(alpha: .94),
                      borderRadius: BorderRadius.circular(18),
                      border: searched
                          ? null
                          : Border.all(color: Colors.lightBlue, width: 3),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: TextStyle(
                          fontFamily: 'Baloo2',
                          fontSize: 22,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          color: searched ? Colors.white : TudloColors.ink,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _scene() {
    final map = [
      _BantayStage.schoolMap,
      _BantayStage.marketMap,
      _BantayStage.farmMap,
    ].contains(_stage);
    if (map) {
      final active = _location;
      return [_prompt('Ginapangita ang $active sa mapa...')];
    }
    return switch (_stage) {
      _BantayStage.house => [
        _prompt('Abyan, wala diri si Bantay! Buligan mo ako pangita sa iya?'),
        _at(
          330,
          245,
          350,
          180,
          _asset('updated/Bantay_Missing_White_Outline.png'),
        ),
        _bottomAction(
          'PANGITAON TA',
          () => unawaited(_go(_BantayStage.schoolMap)),
        ),
      ],
      _BantayStage.classroom => [
        _prompt(
          _searched.length == 3
              ? 'Wala siya diri. Pamangkuton ta ang tindera.'
              : 'Pangitaa si Bantay - ${_searched.length}/3',
        ),
        _hotspot('classroom_desk', 'Lamesa', 214, 218, 245, 132),
        _hotspot('classroom_window', 'Bintana', 535, 112, 245, 160),
        _hotspot('classroom_door', 'Purtahan', 800, 132, 132, 230),
      ],
      _BantayStage.market => [
        _at(
          0,
          0,
          960,
          540,
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => unawaited(_marketOutsideTap()),
          ),
        ),
        _prompt(
          _activeMarketDialogueClip != null
              ? 'Pamati anay.'
              : _clue || _selected == 'vendor' || _selected == 'vendor_reply'
              ? 'Tan-awa sa uma!'
              : 'I-tap ang tindera.',
        ),
        _at(
          462,
          160,
          510,
          360,
          _BantayPulse(
            active: false,
            child: GestureDetector(
              onTap: () => unawaited(_vendor()),
              child: _asset(
                'updated/Market_Stall_With_Vendor_No_Green_Circle.png',
              ),
            ),
          ),
        ),
        if (_activeMarketDialogueClip == '13' ||
            _activeMarketDialogueClip == '16')
          _at(
            310,
            182,
            265,
            94,
            _MarketDialogueBubble(
              text: _marketDialogueText(_activeMarketDialogueClip!)!,
              alignRight: false,
            ),
          ),
        if (_activeMarketDialogueClip == '14' ||
            _activeMarketDialogueClip == '15')
          _at(
            560,
            108,
            300,
            94,
            _MarketDialogueBubble(
              text: _marketDialogueText(_activeMarketDialogueClip!)!,
              alignRight: true,
            ),
          ),
        if (!_clue)
          _at(
            672,
            362,
            82,
            82,
            const IgnorePointer(
              child: AnimatedPointFinger(
                asset: _bantayPointFinger,
                size: 74,
                angle: -.14,
                tapOffset: Offset(8, -4),
              ),
            ),
          ),
      ],
      _BantayStage.farm => [
        _at(
          0,
          0,
          960,
          540,
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => unawaited(_wrongFootprintTap()),
          ),
        ),
        _prompt('Sunda ang footprints - $_footprints/3'),
        for (var i = 0; i < 3; i++)
          _at(
            255 + i * 190,
            356,
            155,
            145,
            _BantayPulse(
              active: _nudging.contains('footprint_$i'),
              wiggle: _nudging.contains('footprint_$i'),
              child: GestureDetector(
                onTap: () => unawaited(_footprint(i)),
                child: Opacity(
                  opacity: i < _footprints ? 1 : .28,
                  child: _asset('updated/Dog_Footprint_Trail.png'),
                ),
              ),
            ),
          ),
        if (_footprints < 3)
          _at(
            292 + _footprints * 190,
            444,
            88,
            88,
            const IgnorePointer(
              child: AnimatedPointFinger(
                asset: _bantayPointFinger,
                size: 82,
                angle: -.16,
                tapOffset: Offset(0, -8),
              ),
            ),
          ),
      ],
      _BantayStage.found => [
        _prompt('Salamat! Nakita naton si Bantay!'),
        _at(
          205,
          130,
          430,
          390,
          const TudloMascot(size: 550, mood: KokaMood.idle),
        ),
        _at(475, 205, 270, 240, _asset('updated/Bantay_Idle.png')),
      ],
      _BantayStage.model => [
        _prompt('Ano ang una, sunod, kag katapusan?'),
        for (final entry in _bantayEvents.indexed)
          _at(
            150 + entry.$1 * 245,
            176,
            230,
            230,
            _event(entry.$2, framed: false),
          ),
      ],
      _BantayStage.sequence => [
        _prompt('Ihan-ay ang nadula, clue, kag nakita.'),
        _at(
          38,
          108,
          884,
          410,
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .72),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFFFC928), width: 4),
            ),
          ),
        ),
        for (var i = 0; i < 3; i++)
          _at(
            75 + i * 290,
            126,
            230,
            202,
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
                    Container(
                      width: double.infinity,
                      height: 42,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1BA7F2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Text(
                        ['UNA', 'SUNOD', 'KATAPUSAN'][i],
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Baloo2',
                          color: Colors.white,
                          fontSize: 20,
                          height: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _slots[i] == null
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                              child: _grayEvent(_bantayEvents[i]),
                            )
                          : _BantayPulse(
                              active: _wiggling.contains(_slots[i]),
                              wiggle: true,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                                child: _event(_slots[i]!, framed: false),
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
              75 + entry.$1 * 290,
              352,
              230,
              154,
              Draggable<String>(
                data: entry.$2,
                maxSimultaneousDrags: _busy ? 0 : 1,
                feedback: Material(
                  color: Colors.transparent,
                  child: SizedBox(
                    width: 230,
                    height: 154,
                    child: _event(entry.$2, framed: false),
                  ),
                ),
                childWhenDragging: const SizedBox.expand(),
                child: GestureDetector(
                  onTap: () {
                    if (!_busy) setState(() => _selected = entry.$2);
                  },
                  child: _BantayPulse(
                    active: _selected == entry.$2,
                    child: _event(entry.$2, framed: false),
                  ),
                ),
              ),
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

  @override
  Widget build(BuildContext context) {
    final background = switch (_location) {
      'House' => 'livingroom.svg',
      'School' => 'ClassroomLandscape 1.svg',
      'Market' => 'MarketLandscape 1.svg',
      _ => 'FarmLandscape 1.svg',
    };
    final backgroundAsset = '$_bantayBackgroundRoot/$background';
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
                        backgroundAsset,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (_stage != _BantayStage.found &&
                        _stage != _BantayStage.model &&
                        _stage != _BantayStage.sequence)
                      _at(
                        _stage == _BantayStage.house
                            ? 112
                            : _stage == _BantayStage.market
                            ? 270
                            : 24,
                        _stage == _BantayStage.house
                            ? 170
                            : _stage == _BantayStage.market
                            ? 280
                            : 200,
                        _stage == _BantayStage.house ? 250 : 195,
                        _stage == _BantayStage.house ? 340 : 300,
                        TudloMascot(
                          size: _stage == _BantayStage.house
                              ? 365
                              : _stage == _BantayStage.farm
                              ? 255
                              : _stage == _BantayStage.market
                              ? 270
                              : 300,
                          mood:
                              _stage == _BantayStage.house ||
                                  _stage == _BantayStage.farm
                              ? KokaMood.curious
                              : KokaMood.idle,
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

class _MarketDialogueBubble extends StatelessWidget {
  final String text;
  final bool alignRight;

  const _MarketDialogueBubble({required this.text, required this.alignRight});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .96),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1BA7F2), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .10),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Baloo2',
                  color: TudloColors.ink,
                  fontSize: 20,
                  height: 1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -10,
          left: alignRight ? null : 24,
          right: alignRight ? 24 : null,
          child: Transform.rotate(
            angle: .78,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .96),
                border: const Border(
                  right: BorderSide(color: Color(0xFF1BA7F2), width: 3),
                  bottom: BorderSide(color: Color(0xFF1BA7F2), width: 3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
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

Future<void> _showGradeThreeMapInstructionDialog(
  BuildContext context, {
  required String message,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: TudloColors.blue, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .18),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Baloo2',
                fontSize: 28,
                height: 1.08,
                fontWeight: FontWeight.w900,
                color: TudloColors.ink,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 180,
            height: 58,
            child: FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: TudloColors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Colors.white, width: 3),
                ),
              ),
              child: const Text(
                'SIGE',
                style: TextStyle(
                  fontFamily: 'Baloo2',
                  fontSize: 26,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
