import 'package:tudloapp/core/services/app_audio_service.dart';

const String lessonNumberVoiceBase = 'audio/VO-final/numbers1-10';

String lessonNumberVoiceAsset(int number) {
  final safeNumber = number.clamp(1, 10);
  return '$lessonNumberVoiceBase/Gr_3_Les_1_1_6_$safeNumber.wav';
}

Future<void> playLessonNumberVoice(int number) async {
  if (!AppAudioService.instance.voiceOverEnabled) return;
  await AppAudioService.instance.lowerBackgroundVolume();
  try {
    await AppAudioService.instance.playVoiceAssets([
      lessonNumberVoiceAsset(number),
    ]);
  } finally {
    await AppAudioService.instance.restoreBackgroundVolume();
  }
}
