abstract class TudloTtsPlatform {
  Future<void> speak(
    String text, {
    required bool hiligaynon,
    required bool waitForCompletion,
  });

  Future<void> stop();
}
