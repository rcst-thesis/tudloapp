/// A single dictionary word entry. [id] is the stable key used for
/// favoriting (persisted in `LearnerProfile.favoritedWords`), independent of
/// [word] so display text can change without breaking saved favorites.
class DictionaryEntry {
  const DictionaryEntry({
    required this.id,
    required this.word,
    required this.phonetic,
    required this.definition,
    required this.example,
    required this.category,
    this.frontCardImage,
    this.favThumbImage,
  });

  final String id;
  final String word;
  final String phonetic;
  final String definition;
  final String example;

  /// Groups entries for the browse screen's category filter/catalog
  /// sections (e.g. "home", "animals", "family").
  final String category;

  /// A fully-designed front-card image (art + word label already baked in)
  /// for the word-of-the-day flip card. Also doubles as this entry's
  /// **word-of-the-day eligibility gate** -- `resolveWordOfTheDay` only
  /// ever picks from entries where this is non-null, since the flip
  /// card's front face has nothing worth showing otherwise.
  final String? frontCardImage;

  /// A fully-designed small card image (art + word label already baked in)
  /// for the favorites carousel and browse-screen featured tray. Also
  /// doubles as this entry's **featured-tray eligibility gate** --
  /// `resolveFeatured` only ever picks from entries where this is
  /// non-null. When null, this entry still appears in the favorites
  /// carousel/search thumbnails as a blank card (word label, no image), just
  /// never in the featured tray.
  final String? favThumbImage;
}
