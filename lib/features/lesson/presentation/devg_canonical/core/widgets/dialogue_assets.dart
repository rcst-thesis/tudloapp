import 'package:flutter/material.dart';

class TudloDialogueAssets {
  static const dialogueBox = 'assets/images/dialogue/dialoguebox.png';
  static const speechBubble = 'assets/images/dialogue/speech-bubble.png';
  static const questionBubble =
      'assets/images/dialogue/question-bubble-juan.png';
  static const speakerIcon = 'assets/images/dialogue/speaker-icon.png';
  static const tuonTa = 'assets/images/dialogue/tuon-ta!.png';
}

class TudloSpeakerIcon extends StatelessWidget {
  final double size;

  const TudloSpeakerIcon({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      TudloDialogueAssets.speakerIcon,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
  }
}
