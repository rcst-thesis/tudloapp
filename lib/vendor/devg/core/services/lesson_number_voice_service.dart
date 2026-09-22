import 'package:tudloapp/vendor/devg/core/services/app_audio_service.dart';

const lessonNumberVoiceBase = 'audio/VO-final/numbers1-10';

String lessonNumberVoiceAsset(int number) =>
    '$lessonNumberVoiceBase/Gr_3_Les_1_1_6_${number.clamp(1, 10)}.wav';

Future<void> playLessonNumberVoice(int number) =>
    AppAudioService.instance.playVoiceAssets([lessonNumberVoiceAsset(number)]);
