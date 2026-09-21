import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:tudloapp/shared/widgets/rive_avatar.dart';
import 'package:tudloapp/shared/widgets/rive_avatar_background.dart';
import 'package:tudloapp/shared/widgets/sticker_press_button.dart';

/// [MeEditDialog]'s result on Save -- `null` if dismissed/cancelled instead.
///
/// Deliberately just data, not a direct [LearnerController] mutation: a
/// dialog shown via `showGeneralDialog` is pushed as its own Navigator
/// route, a sibling of the route "/"'s own subtree in the Overlay -- not a
/// descendant of it -- so `LearnerScope.of(context)` called from *inside*
/// this dialog would not find the same ancestor the rest of the app
/// watches and would silently fall back to a throwaway ephemeral
/// controller (same reasoning `me_screen.dart`'s own
/// `_LogoutConfirmationDialog` already follows: it only returns a bool and
/// leaves the actual `LearnerScope.of(context).logOut()` call to
/// `_MeScreenState`, which has the correct ancestor context). The caller
/// applies this result with its own context instead.
typedef MeEditResult = ({String name, String avatarId});

/// The Me screen's "Edit" popup: lets the learner rename themselves and
/// pick a Koka avatar (an Artboard from `assets/images/avatar.riv`).
/// Returns the edit as a [MeEditResult] on Save (or `null` if
/// cancelled/dismissed) -- see [MeEditResult] for why it doesn't persist
/// anything itself.
class MeEditDialog extends StatefulWidget {
  const MeEditDialog({
    required this.learnerName,
    required this.grade,
    required this.userCode,
    required this.avatarId,
    this.onAvatarSelected,
    super.key,
  });

  final String learnerName;
  final int grade;
  final String userCode;
  final String avatarId;
  final ValueChanged<String>? onAvatarSelected;

  @override
  State<MeEditDialog> createState() => _MeEditDialogState();
}

class _MeEditDialogState extends State<MeEditDialog> {
  static const _cream = Color(0xFFFFE49A);
  static const _brown = Color(0xFF9C7C21);
  static const _mutedBrown = Color(0xFFA07B57);
  static const _mutedLabel = Color(0xFFAD9E8B);

  late final TextEditingController _nameController;
  late final FocusNode _nameFocusNode;
  late String _draftAvatarId;

  /// Every Artboard currently in `avatar.riv`, by name -- read once from
  /// the file itself rather than a hardcoded count, so the grid grows
  /// automatically as more avatars are added to the same file later. Falls
  /// back to just [widget.avatarId] if the file can't be inspected (e.g. no
  /// native Rive backend available).
  List<String> _availableAvatarIds = const [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.learnerName);
    _nameFocusNode = FocusNode()..addListener(() => setState(() {}));
    _draftAvatarId = widget.avatarId;
    unawaited(_loadAvatarIds());
  }

  Future<void> _loadAvatarIds() async {
    final ids = await RiveAvatar.availableArtboardIds();
    if (!mounted || ids.isEmpty) return;
    setState(() => _availableAvatarIds = ids);
  }

  List<String> get _avatarIds =>
      _availableAvatarIds.isNotEmpty ? _availableAvatarIds : [_draftAvatarId];

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _save(BuildContext context) {
    final newName = _nameController.text.trim();
    Navigator.of(context).pop<MeEditResult>((
      name: newName.isNotEmpty ? newName : widget.learnerName,
      avatarId: _draftAvatarId,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 373),
            child: Stack(
              // The tab needs to poke out above the card's own top edge, so
              // it has to sit outside the ClipRRect that clips the postmark
              // decoration to the card's rounded corners below.
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: Container(
                    key: const Key('me-edit-dialog'),
                    color: Colors.white,
                    child: Stack(
                      children: [
                        // Purely decorative -- same postmark flourish as
                        // the learner card's own header art
                        // (`me_learner_card.svg`), at the same position
                        // relative to the card: fully inside the card, not
                        // clipped at a corner (its circles top out at
                        // y:24/x:250 in that art's 374-wide canvas, so
                        // `top`/`right` here are measured from this
                        // Container's own unpadded edges, matching that).
                        // Excluded from semantics so screen readers skip
                        // straight to the actual content below.
                        Positioned(
                          top: 13,
                          right: 0,
                          child: ExcludeSemantics(
                            child: SvgPicture.asset(
                              'assets/images/me_edit_deco_postmark.svg',
                              width: 108,
                              height: 72,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      key: const Key('me-edit-avatar-preview'),
                                      width: 94,
                                      height: 123,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            RiveAvatarBackground(
                                              grade: widget.grade,
                                            ),
                                            // `RiveAvatar` itself always
                                            // fits its artboard with
                                            // `Fit.contain` (shared with
                                            // the Me screen's card and the
                                            // tile grid, so not changed
                                            // globally) -- scaled up here
                                            // specifically so it reads
                                            // bigger in this larger
                                            // preview box; the ClipRRect
                                            // above crops whatever spills
                                            // past the rounded corners.
                                            Transform.scale(
                                              scale: 1.25,
                                              child: RiveAvatar(
                                                artboardId: _draftAvatarId,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          TextField(
                                            key: const Key(
                                              'me-edit-name-field',
                                            ),
                                            controller: _nameController,
                                            focusNode: _nameFocusNode,
                                            maxLength: 20,
                                            style: const TextStyle(
                                              fontFamily: 'ComicRelief',
                                              fontSize: 20,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.black,
                                            ),
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              border: InputBorder.none,
                                              counterText: '',
                                            ),
                                          ),
                                          // "editable" affordance -- the name is the
                                          // only field in this dialog that can be
                                          // changed (grade/user code below are plain,
                                          // non-interactive `Text`), so it's the only
                                          // one that gets this. Fades out while the
                                          // field is actively focused so it doesn't
                                          // compete with the name being typed, and
                                          // fades back in once focus leaves it.
                                          AnimatedOpacity(
                                            duration: const Duration(
                                              milliseconds: 150,
                                            ),
                                            opacity: _nameFocusNode.hasFocus
                                                ? 0
                                                : 1,
                                            child: const Text(
                                              'tap to edit',
                                              style: TextStyle(
                                                fontFamily: 'ComicRelief',
                                                fontSize: 9,
                                                color: _mutedLabel,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'grade ${widget.grade}',
                                            style: const TextStyle(
                                              fontFamily: 'ComicRelief',
                                              fontSize: 14,
                                              fontWeight: FontWeight.w400,
                                              color: Color(0xFFD5B488),
                                            ),
                                          ),
                                          // The learner card itself leaves
                                          // this same generous pause (24px,
                                          // vs. 3px above/0px below) between
                                          // grade and user code -- that gap
                                          // is what gives the card's header
                                          // its "relaxed" feel rather than
                                          // every line packed tight.
                                          const SizedBox(height: 24),
                                          const Text(
                                            'user code',
                                            style: TextStyle(
                                              fontFamily: 'ComicRelief',
                                              fontSize: 11,
                                              fontWeight: FontWeight.w400,
                                              color: _mutedLabel,
                                            ),
                                          ),
                                          Text(
                                            widget.userCode,
                                            style: const TextStyle(
                                              fontFamily: 'ComicRelief',
                                              fontSize: 13,
                                              // Unlike "grade"/"user code"
                                              // above (both explicitly
                                              // w400), the card's own
                                              // user-code value leaves
                                              // `SvgCardText`'s fontWeight
                                              // unset -- which defaults to
                                              // w700, i.e. bold.
                                              fontWeight: FontWeight.w700,
                                              color: _mutedBrown,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                _AvatarGrid(
                                  key: const Key('me-edit-avatar-grid'),
                                  avatarIds: _avatarIds,
                                  selectedAvatarId: _draftAvatarId,
                                  onSelected: (avatarId) {
                                    setState(() => _draftAvatarId = avatarId);
                                    widget.onAvatarSelected?.call(avatarId);
                                  },
                                ),
                                const SizedBox(height: 20),
                                // Fixed 164-wide, centered -- per Figma,
                                // not a full-width button like the rest of
                                // the app's usual StickerPressButton calls.
                                Center(
                                  child: SizedBox(
                                    width: 164,
                                    child: StickerPressButton(
                                      key: const Key('me-edit-save-button'),
                                      label: 'save',
                                      frontColor: _cream,
                                      depthColor: _brown,
                                      labelColor: _brown,
                                      height: 41,
                                      restLift: 4,
                                      borderRadius: 13,
                                      fontSize: 18,
                                      onPressed: () => _save(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  // Same rects as the learner card's own baked tab
                  // (`me_learner_card.svg`: y:0, height 27.2/24 against
                  // that card's white body starting at y:11) -- 11px pokes
                  // above this card's top edge, the rest overlaps it,
                  // rendered on top since this sits after the ClipRRect in
                  // paint order.
                  top: -11,
                  child: ExcludeSemantics(
                    child: SvgPicture.asset(
                      'assets/images/me_edit_deco_tab.svg',
                      width: 44,
                      height: 28,
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
}

/// The Edit popup's avatar grid: always exactly [_crossAxisCount] columns,
/// whatever width it's actually given, with a fresh row started every
/// [_crossAxisCount] avatars -- unlike a `Wrap`, which only stays at 4
/// columns by luck (it wraps whenever the next tile doesn't fit the
/// remaining width, so a fixed tile size can silently drop to 3 per row on
/// a narrower card). [_AvatarTile]'s own size is computed here from the
/// available width instead of hardcoded, so the grid is always exactly
/// [_crossAxisCount] wide and however many rows follow from
/// `avatarIds.length` (2 rows for today's 8 avatars).
class _AvatarGrid extends StatelessWidget {
  const _AvatarGrid({
    required this.avatarIds,
    required this.selectedAvatarId,
    required this.onSelected,
    super.key,
  });

  final List<String> avatarIds;
  final String selectedAvatarId;
  final ValueChanged<String> onSelected;

  static const _crossAxisCount = 4;
  static const _spacing = 8.0;
  static const _runSpacing = 12.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileSize =
            (constraints.maxWidth - _spacing * (_crossAxisCount - 1)) /
            _crossAxisCount;
        final rows = <Widget>[];
        for (var i = 0; i < avatarIds.length; i += _crossAxisCount) {
          final rowIds = avatarIds.skip(i).take(_crossAxisCount).toList();
          if (rows.isNotEmpty) {
            rows.add(const SizedBox(height: _runSpacing));
          }
          rows.add(
            // Centered rather than left-aligned so a partial last row
            // (avatarIds.length not a multiple of _crossAxisCount) sits in
            // the middle of the grid's width instead of hugging the left
            // edge -- a full row of 4 already fills that width exactly, so
            // this only visibly matters for a trailing partial row.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var j = 0; j < rowIds.length; j++) ...[
                  if (j > 0) const SizedBox(width: _spacing),
                  _AvatarTile(
                    key: Key('me-edit-avatar-tile-${rowIds[j]}'),
                    avatarId: rowIds[j],
                    size: tileSize,
                    selected: rowIds[j] == selectedAvatarId,
                    onTap: () => onSelected(rowIds[j]),
                  ),
                ],
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    required this.avatarId,
    required this.size,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String avatarId;
  final double size;
  final bool selected;
  final VoidCallback onTap;

  // Noticeably darker than the shared `_brown` used elsewhere in this
  // dialog (e.g. the Save button) -- at this tile's small size the usual
  // cream/brown pairing reads too flat, so the depth layer here gets extra
  // contrast to keep the sticker-press lip legible.
  static const _depth = Color(0xFF9C7C21);

  @override
  Widget build(BuildContext context) {
    // Proportional to `size` (the ~61px tile this replaced used radius
    // 12/8) so the tile keeps the same look whatever width the grid
    // actually computes it at.
    final outerRadius = size * 12 / 61;
    final innerRadius = size * 8 / 61;
    return Semantics(
      button: true,
      selected: selected,
      label: 'avatar $avatarId',
      child: SizedBox(
        width: size,
        height: size,
        // `StickerPressButton`'s two layers round their own corners via
        // `BoxDecoration`, not an actual clip -- at this tile's small,
        // fractional (LayoutBuilder-computed) size, that let a hairline of
        // the square-edged depth layer peek out past the curve, most
        // visible right when the tap animation moves the front layer.
        // Clipping the whole button to the same radius guarantees nothing
        // ever paints outside the tile's rounded silhouette.
        child: ClipRRect(
          borderRadius: BorderRadius.circular(outerRadius),
          child: StickerPressButton(
            onPressed: onTap,
            playButtonSound: false,
            frontColor: const Color(0xFFFFE49A),
            depthColor: _depth,
            // Figma's own tile spec has a 3px lift at rest (much shallower
            // than this button's usual 5-7px default -- these are small
            // tiles, a bigger lift would look exaggerated). Selected tiles
            // sit closer to fully pressed, unselected ones keep that rest
            // lift -- same "smaller lift reads as active" convention
            // grade_selection_screen.dart already uses.
            restLift: selected ? 2 : 5,
            borderRadius: outerRadius,
            child: SizedBox.expand(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(innerRadius),
                child: RiveAvatar(artboardId: avatarId),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
