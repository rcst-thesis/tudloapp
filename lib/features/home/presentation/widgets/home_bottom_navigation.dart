import 'package:flutter/material.dart';

import 'package:tudloapp/shared/audio/tudlo_audio_scope.dart';

class HomeBottomNavigation extends StatelessWidget {
  const HomeBottomNavigation({
    this.onItemTapped,
    this.selectedIndex = 0,
    this.backgroundColor = _defaultBackgroundColor,
    this.selectedTileColor = _defaultSelectedTileColor,
    this.labelColor = Colors.white,
    super.key,
  }) : assert(selectedIndex >= 0 && selectedIndex < 6);

  static const _defaultBackgroundColor = Color(0xFFBD8C57);
  static const _defaultSelectedTileColor = Color(0xFF966E42);

  final ValueChanged<int>? onItemTapped;
  final int selectedIndex;
  final Color backgroundColor;
  final Color selectedTileColor;
  final Color labelColor;

  static const _items = <_HomeNavigationItem>[
    _HomeNavigationItem(
      label: 'home',
      asset: 'assets/images/home_nav_home.png',
      displayWidth: 46,
      displayHeight: 33,
    ),
    _HomeNavigationItem(
      label: 'translate',
      asset: 'assets/images/home_nav_translate.png',
      displayWidth: 35,
      displayHeight: 37,
    ),
    _HomeNavigationItem(
      label: 'lessons',
      asset: 'assets/images/home_nav_lessons.png',
      displayWidth: 38,
      displayHeight: 33,
    ),
    _HomeNavigationItem(
      label: 'map',
      asset: 'assets/images/home_nav_map.png',
      displayWidth: 45,
      displayHeight: 36,
    ),
    _HomeNavigationItem(
      label: 'dictionary',
      asset: 'assets/images/home_nav_dictionary.png',
      displayWidth: 31,
      displayHeight: 36,
    ),
    _HomeNavigationItem(
      label: 'me',
      asset: 'assets/images/home_nav_me.png',
      displayWidth: 43,
      displayHeight: 31,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return SizedBox(
      height: 66 + bottomInset,
      child: Material(
        key: const Key('home-bottom-navigation'),
        color: backgroundColor,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final labelFontSize = _sharedLabelFontSize(
                      context,
                      constraints.maxWidth,
                    );
                    return SizedBox(
                      height: 66,
                      child: Transform.translate(
                        offset: const Offset(0, 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var index = 0; index < _items.length; index++)
                              Expanded(
                                child: _NavigationButton(
                                  item: _items[index],
                                  selected: index == selectedIndex,
                                  selectedTileColor: selectedTileColor,
                                  labelColor: labelColor,
                                  labelFontSize: labelFontSize,
                                  onTap: () => onItemTapped?.call(index),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _sharedLabelFontSize(BuildContext context, double navigationWidth) {
    const preferredSize = 10.5;
    const tileWidthLimitedByHeight = 64.0 * .92;
    final itemInnerWidth = (navigationWidth / _items.length) - 4;
    final tileWidth = itemInnerWidth < tileWidthLimitedByHeight
        ? itemInnerWidth
        : tileWidthLimitedByHeight;
    // Reserve the tile padding plus two extra pixels of breathing room on each
    // side. The longest label controls one shared size for all six labels.
    final availableWidth = tileWidth - 12;
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'dictionary',
        style: TextStyle(
          fontFamily: 'ComicRelief',
          fontSize: preferredSize,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    if (textPainter.width <= availableWidth) return preferredSize;
    return preferredSize * (availableWidth / textPainter.width);
  }
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
    required this.item,
    required this.selected,
    required this.selectedTileColor,
    required this.labelColor,
    required this.labelFontSize,
    required this.onTap,
  });

  final _HomeNavigationItem item;
  final bool selected;
  final Color selectedTileColor;
  final Color labelColor;
  final double labelFontSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: Center(
        child: AspectRatio(
          aspectRatio: .92,
          child: Material(
            key: Key('home-nav-tile-${item.label}'),
            color: selected ? selectedTileColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: Key('home-nav-${item.label}'),
              onTap: () {
                TudloAudioScope.maybeOf(context)?.playButtonTapSound();
                onTap();
              },
              borderRadius: BorderRadius.circular(12),
              child: Semantics(
                button: true,
                selected: selected,
                label: item.label,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 4,
                  ),
                  child: Column(
                    children: [
                      Flexible(
                        child: SizedBox(
                          height: 37,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: RepaintBoundary(
                              child: Image.asset(
                                item.asset,
                                width: item.displayWidth,
                                height: item.displayHeight,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                                excludeFromSemantics: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.label,
                        key: Key('home-nav-label-${item.label}'),
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          color: labelColor,
                          fontFamily: 'ComicRelief',
                          fontSize: labelFontSize,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeNavigationItem {
  const _HomeNavigationItem({
    required this.label,
    required this.asset,
    required this.displayWidth,
    required this.displayHeight,
  });
  final String label;
  final String asset;
  final double displayWidth;
  final double displayHeight;
}
