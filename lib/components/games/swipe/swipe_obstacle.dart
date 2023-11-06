import 'dart:math';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:untitled_rhythm_game/components/games/swipe/ship_component.dart';
import 'package:untitled_rhythm_game/components/mixins/level_size_aware.dart';
import 'package:untitled_rhythm_game/off_beat_game.dart';
import 'package:untitled_rhythm_game/components/level/song_level_component.dart';

class SwipeObstacle extends PositionComponent
    with HasGameRef<OffBeatGame>, LevelSizeAware {
  static const int numberOfAsteroidAssets = 3;

  /// Percentage of the Y gameSize that calculates the height of this component.
  static const double obstacleYLengthPercentage =
      ShipComponent.hitCircleYPlacementModifier /
          SongLevelComponent.INTERVAL_TIMING_MULTIPLIER;

  /// Width of the image.
  final double imageWidth;

  /// Time (in seconds) that this obstacle was expected to be loaded.
  final double expectedTimeOfStart;

  /// Max distance that the obstacle travels before automatic removal.
  final double fullObstacleTravelDistance;

  /// Max time (in seconds) that the obstacle is displayed before automatic removal.
  final double timeObstacleIsVisible;

  /// True when the player/ship has collided with this obstacle.
  bool hasCollidedWithShip = false;

  SwipeObstacle({
    super.position,
    super.priority,
    required this.imageWidth,
    required this.expectedTimeOfStart,
    required this.fullObstacleTravelDistance,
    required this.timeObstacleIsVisible,
  }) : super(anchor: Anchor.bottomLeft);

  double get currentTimingOfObstacle =>
      gameRef.currentLevel.songTime - expectedTimeOfStart;

  Future<void> onLoad() async {
    setLevelSize();
    size = Vector2(imageWidth, levelSize.y * obstacleYLengthPercentage);
    int randomAsteroidAssetIndex = Random().nextInt(numberOfAsteroidAssets) + 1;
    add(SpriteComponent(
      sprite: await Sprite.load('asteroid$randomAsteroidAssetIndex.png'),
      size: size,
    ));
    // Add a rectangular HitBox with a bit of vertical leniency.
    add(RectangleHitbox(
      size: Vector2(size.x, size.y * 0.8),
      position: Vector2(0, size.y * 0.1),
    )..collisionType = CollisionType.passive);
    double currentTiming = currentTimingOfObstacle;
    final double currentProgress = currentTiming / timeObstacleIsVisible;
    position.y = min(currentProgress, 1) * fullObstacleTravelDistance;
    // Add Effect to move to the end location.
    add(MoveEffect.to(Vector2(0, fullObstacleTravelDistance),
        LinearEffectController(timeObstacleIsVisible - currentTiming)));
    await super.onLoad();
  }
}
