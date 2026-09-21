import 'package:tudloapp/features/home/presentation/widgets/home_dev_panel_frame.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_dev_panel_label.dart';
import 'package:tudloapp/features/home/presentation/widgets/home_sticker_container.dart';

/// Editable positions measured from the original 412-wide Figma artboard.
///
/// HomeScene multiplies these design-space values by its available width. Keep
/// artwork ratios here so visual assets stay proportional at every viewport.
abstract final class HomeSceneLayout {
  static const double designWidth = 412;

  static const window = HomeSceneItemLayout(
    left: 206,
    top: 143,
    width: 128,
    height: 128,
  );
  static const door = HomeSceneItemLayout(
    left: 326,
    top: 230,
    width: 73,
    height: 121,
  );

  static const double bookshelfWidth = 160;
  static const double _bookshelfAspectRatio = 37 / 160;
  static const bookshelf = HomeSceneItemLayout(
    left: 7,
    top: 215,
    width: bookshelfWidth,
    height: bookshelfWidth * _bookshelfAspectRatio,
  );

  static const double standingLampHeight = 126;
  static const double _standingLampAspectRatio = 145 / 504;
  static const standingLamp = HomeSceneItemLayout(
    left: 25,
    top: 245,
    width: standingLampHeight * _standingLampAspectRatio,
    height: standingLampHeight,
  );

  static const double drawerWidth = 52;
  static const double _drawerAspectRatio = 41 / 52;
  static const drawer = HomeSceneItemLayout(
    left: 53,
    top: 325,
    width: drawerWidth,
    height: drawerWidth * _drawerAspectRatio,
  );

  static const double couchWidth = 152;
  static const double _couchAspectRatio = 79 / 152;
  static const couch = HomeSceneItemLayout(
    left: 110,
    top: 287,
    width: couchWidth,
    height: couchWidth * _couchAspectRatio,
  );

  static const double lilyMatWidth = 361;
  static const double _lilyMatAspectRatio = 88 / 361;
  static const lilyMat = HomeSceneItemLayout(
    left: 5,
    top: 359,
    width: lilyMatWidth,
    height: lilyMatWidth * _lilyMatAspectRatio,
  );

  static const double kokaMascotHeight = 140;
  static const double _kokaMascotAspectRatio = 312 / 573;
  static const kokaMascot = HomeSceneItemLayout(
    left: 160,
    top: 260,
    width: kokaMascotHeight * _kokaMascotAspectRatio,
    height: kokaMascotHeight,
  );

  static const double wordOfTheDayWidth = 378;
  static const double _wordOfTheDayAspectRatio = 216 / 378;
  static const wordOfTheDay = HomeSceneItemLayout(
    left: 17,
    top: 480,
    width: wordOfTheDayWidth,
    height: wordOfTheDayWidth * _wordOfTheDayAspectRatio,
  );
  static const lessonPanel = HomeSceneItemLayout(
    left: 17,
    top: 716,
    width: 378,
    height: 130,
  );

  static const stickerContainer = HomeSceneItemLayout(
    left: 17,
    top: 0,
    width: HomeStickerContainer.designWidth,
    height: HomeStickerContainer.designHeight,
  );
  static const double stickerContainerTopGap = 20;

  static const devPanelLabel = HomeSceneItemLayout(
    left: 17,
    top: 0,
    width: HomeDevPanelLabel.designWidth,
    height: HomeDevPanelLabel.designHeight,
  );
  static const double devPanelLabelTopGap = 28;
  static const devPanelFrame = HomeSceneItemLayout(
    left: 17,
    top: 0,
    width: HomeDevPanelFrame.designWidth,
    height: HomeDevPanelFrame.designHeight,
  );
  static const double devPanelFrameTopGap = 12;
  static const double devPanelFrameBottomGap = 8;

  static const double footerHeight = 48;
  static const double creamFloorBorderTop = 346;
  static const double floorTop = 350;

  static double stickerContainerTopFor(double lessonPanelHeight) =>
      lessonPanel.top + lessonPanelHeight + stickerContainerTopGap;

  static double devPanelLabelTopFor(double lessonPanelHeight) =>
      stickerContainerTopFor(lessonPanelHeight) +
      stickerContainer.height +
      devPanelLabelTopGap;

  static double devPanelFrameTopFor(double lessonPanelHeight) =>
      devPanelLabelTopFor(lessonPanelHeight) +
      devPanelLabel.height +
      devPanelFrameTopGap;

  /// Update this calculation whenever an item is added below the developer
  /// panel; the scroll extent and footer position then remain correct.
  static double footerBottomFor(double lessonPanelHeight) =>
      stickerContainerTopFor(lessonPanelHeight) +
      stickerContainer.height +
      devPanelLabelTopGap +
      devPanelLabel.height +
      devPanelFrameTopGap +
      devPanelFrame.height +
      devPanelFrameBottomGap +
      footerHeight;
}

/// One item's editable Figma coordinates and native size.
class HomeSceneItemLayout {
  const HomeSceneItemLayout({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;
}
