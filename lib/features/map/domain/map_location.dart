/// A tappable location on Koka's barangay map.
///
/// Two separate identities, deliberately kept independent:
/// - [persistedId] is the stable Flutter-side identity used wherever a
///   location id is persisted or compared (e.g.
///   `LearnerProfile.unlockedMapLocations`) -- just the enum name, so it
///   never changes just because a future map art export renames something.
/// - [riveId] matches the Rive `MapState` view model's per-location
///   namespace exactly (e.g. `house/isUnlocked`, `house/locationTapped`) --
///   the enum name for every location except [plaza], whose Rive-side
///   property is named `park` (kept as `plaza` on the Flutter side since
///   that's the established name throughout this codebase; only the
///   Rive-facing id differs).
enum MapLocation {
  house,
  school,
  plaza,
  market,
  farm,
  beach,
  church,
  hospital;

  String get persistedId => name;

  String get riveId => this == MapLocation.plaza ? 'park' : name;

  /// The [MapLocation] whose [persistedId] matches [id], or `null` if none
  /// does -- e.g. a stale id from a saved learner profile if a location is
  /// ever renamed or removed.
  static MapLocation? fromPersistedId(String id) {
    for (final location in values) {
      if (location.persistedId == id) return location;
    }
    return null;
  }
}
