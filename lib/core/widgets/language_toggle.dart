import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tudloapp/core/services/app_audio_service.dart';
import 'package:tudloapp/core/services/tudlo_tts_platform.dart';
import 'package:tudloapp/core/services/tudlo_tts_platform_interface.dart';
import 'package:tudloapp/core/state/app_state.dart';
import 'package:tudloapp/core/theme/app_theme.dart';
import 'package:tudloapp/core/widgets/dialogue_assets.dart';

class TudloLanguageToggle extends StatelessWidget {
  const TudloLanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final isHil = appState.isHiligaynon;

    return Semantics(
      button: true,
      label: 'Switch language',
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: appState.toggleAppLanguage,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 46,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: TudloColors.forest, width: 3),
            boxShadow: [
              BoxShadow(
                color: TudloColors.forest.withValues(alpha: .18),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _LanguagePill(label: 'HIL', active: isHil),
              const SizedBox(width: 4),
              _LanguagePill(label: 'EN', active: !isHil),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguagePill extends StatelessWidget {
  final String label;
  final bool active;

  const _LanguagePill({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 48,
      height: 34,
      decoration: BoxDecoration(
        color: active ? TudloColors.green : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : TudloColors.muted,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class TudloVoiceButton extends StatelessWidget {
  static final TudloTtsPlatform _tts = createTudloTtsPlatform();
  static final ValueNotifier<bool> isSpeaking = ValueNotifier<bool>(false);
  static int _speechToken = 0;

  static const _voBase = 'audio/VO';

  static final Map<String, List<String>> _recordedHilVoice = {
    'hi abyan ano imo ngalan': ['$_voBase/Username.mp3'],
    'abyan sa ano nga grado ka na': ['$_voBase/Grade-level.mp3'],
    'maayong pag abot abyan': ['$_voBase/Maayong-pag-abot.mp3'],
    'tum oka ini para makaumpisa kita': [
      '$_voBase/Tum-oka-ini-para-makaumpisa-kita.mp3',
    ],
    'maayong pag abot abyan diri makatuon kita sang hiligaynon paagi sa sari sari nga leksiyon istorya mga ehemplo kag kaliliagaw nga mga buluhaton':
        ['$_voBase/Onboarding1.mp3'],
    'diri puwede ka man makapangita sang mga tinaga nga gusto mo mahibaluan kag kon ano ang ila kahulugan':
        ['$_voBase/Onboarding2.mp3'],
    'puwede mo man diri mahubad ang imo mga tinaga halin sa hiligaynon pakadto sa english ukon halin sa english pakadto sa hiligaynon':
        ['$_voBase/Onboarding3.mp3'],
    'tuon ta a n t kag y': ['$_voBase/Level1-ANTY.mp3'],
    'abyan kilala mo kon sin o ini siya si': [
      '$_voBase/Abyan-kilala-mo-kon-sino-ini.mp3',
    ],
    'maayo gid abyan padayon kita': [
      '$_voBase/Maayo-gid-abyan-padayon-kita.mp3',
    ],
    'pamatii ang tingog pindoton ang husto nga letra': [
      '$_voBase/Pamatii-ang-tingog.mp3',
    ],
    'pamatia ang tinaga pilia ang kulang nga letra': [
      '$_voBase/Pamatia-ang-tinaga.mp3',
    ],
    'unahon ta pangitaon ang letra nga mabatian mo': [
      '$_voBase/Unahon-ta-pangitaon.mp3',
    ],
    'guyoda ang mga letra para matapos ang tinaga': [
      '$_voBase/Guyuda-ang-mga-letra.mp3',
    ],
    'ara na tanan nga letra': ['$_voBase/Ara-na-tanan-nga-letra.mp3'],
    'husto natapos mo': ['$_voBase/Husto-natapos-mo.mp3'],
    'natapos mo na ang leksyon': ['$_voBase/Natapos-mo-na-ang-leksyon.mp3'],
    'nanay': ['$_voBase/Nanay.mp3'],
    'tatay': ['$_voBase/Tatay.mp3'],
    'ah': ['$_voBase/Sound-A.mp3'],
    'n': ['$_voBase/Sound-N.mp3'],
    't': ['$_voBase/Sound-T.mp3'],
    'y': ['$_voBase/Sound-Y.mp3'],
    'ang tunog sang letra nga a amo ang': [
      '$_voBase/Ang-tunog-sng-letra-nga.mp3',
      '$_voBase/Letter-A.mp3',
      '$_voBase/Amo-ang.mp3',
    ],
    'ang tunog sang letra nga n amo ang': [
      '$_voBase/Ang-tunog-sng-letra-nga.mp3',
      '$_voBase/Letter-N.mp3',
      '$_voBase/Amo-ang.mp3',
    ],
    'ang tunog sang letra nga t amo ang': [
      '$_voBase/Ang-tunog-sng-letra-nga.mp3',
      '$_voBase/Letter-T.mp3',
      '$_voBase/Amo-ang.mp3',
    ],
    'ang tunog sang letra nga y amo ang': [
      '$_voBase/Ang-tunog-sng-letra-nga.mp3',
      '$_voBase/Letter-Y.mp3',
      '$_voBase/Amo-ang.mp3',
    ],
    'may ara letra nga a sa may nanay': [
      '$_voBase/May-ara-letra-nga.mp3',
      '$_voBase/Letter-A.mp3',
      '$_voBase/Sa-may.mp3',
      '$_voBase/Nanay.mp3',
    ],
    'may ara letra nga n sa may nanay': [
      '$_voBase/May-ara-letra-nga.mp3',
      '$_voBase/Letter-N.mp3',
      '$_voBase/Sa-may.mp3',
      '$_voBase/Nanay.mp3',
    ],
    'may ara letra nga t sa may tatay': [
      '$_voBase/May-ara-letra-nga.mp3',
      '$_voBase/Letter-T.mp3',
      '$_voBase/Sa-may.mp3',
      '$_voBase/Tatay.mp3',
    ],
    'may ara letra nga y sa may nanay kag tatay': [
      '$_voBase/May-ara-letra-nga.mp3',
      '$_voBase/Letter-Y.mp3',
      '$_voBase/Sa-may.mp3',
      '$_voBase/Nanay.mp3',
      '$_voBase/Kag.mp3',
      '$_voBase/Tatay.mp3',
    ],
  };

  static Future<void> speak(
    BuildContext context,
    String message, {
    bool hiligaynon = true,
    bool waitForCompletion = false,
  }) async {
    final text = message.trim();
    if (text.isEmpty) return;
    final audio = AppAudioService.instance;
    if (!audio.voiceOverEnabled) return;
    try {
      await _tts.stop();
      await audio.stopVoice();
      isSpeaking.value = false;
      final token = ++_speechToken;
      await audio.lowerBackgroundVolume();
      isSpeaking.value = true;
      final recordedAssets = hiligaynon
          ? _recordedHilVoice[_voiceKey(text)]
          : null;
      if (recordedAssets != null) {
        try {
          final playback = audio.playVoiceAssets(recordedAssets);
          if (waitForCompletion) {
            await playback;
            if (_speechToken == token) isSpeaking.value = false;
            await audio.restoreBackgroundVolume();
          } else {
            unawaited(
              playback.whenComplete(() async {
                if (_speechToken == token) isSpeaking.value = false;
                if (_speechToken == token) {
                  await audio.restoreBackgroundVolume();
                }
              }),
            );
          }
          return;
        } catch (_) {
          await audio.stopVoice();
          if (_speechToken == token) isSpeaking.value = true;
        }
      }
      await _tts.speak(
        text,
        hiligaynon: hiligaynon,
        waitForCompletion: waitForCompletion,
      );
      if (waitForCompletion) {
        if (_speechToken == token) isSpeaking.value = false;
        await audio.restoreBackgroundVolume();
      } else {
        _resetSpeakingAfterEstimate(text, token);
      }
    } catch (_) {
      isSpeaking.value = false;
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));
    }
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
      await AppAudioService.instance.stopVoice();
      _speechToken++;
      isSpeaking.value = false;
      await AppAudioService.instance.restoreBackgroundVolume();
    } catch (_) {
      // Stopping narration should never block navigation.
    }
  }

  static void _resetSpeakingAfterEstimate(String text, int token) {
    final milliseconds = (text.length * 110).clamp(1200, 14000);
    Future<void>.delayed(Duration(milliseconds: milliseconds), () async {
      if (_speechToken == token) isSpeaking.value = false;
      if (_speechToken == token) {
        await AppAudioService.instance.restoreBackgroundVolume();
      }
    });
  }

  static String _voiceKey(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  final String message;
  final String tooltip;
  final double size;
  final bool? hiligaynon;
  final Color backgroundColor;
  final Color foregroundColor;

  const TudloVoiceButton({
    super.key,
    required this.message,
    this.tooltip = 'Play voice message',
    this.size = 54,
    this.hiligaynon,
    this.backgroundColor = TudloColors.forest,
    this.foregroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final glowColor = backgroundColor == Colors.white
        ? TudloColors.green
        : backgroundColor;
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: .40),
            blurRadius: 22,
            spreadRadius: 3,
          ),
          BoxShadow(
            color: TudloColors.forest.withValues(alpha: .18),
            blurRadius: 12,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: IconButton.filled(
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          minimumSize: Size(size, size),
          iconSize: size * .56,
        ),
        onPressed: () async {
          final appState = AppStateScope.of(context);
          final useHiligaynon = hiligaynon ?? appState.isHiligaynon;
          unawaited(AppAudioService.instance.playTap());
          await speak(context, message, hiligaynon: useHiligaynon);
        },
        icon: TudloSpeakerIcon(size: size * .54),
      ),
    );
  }
}
