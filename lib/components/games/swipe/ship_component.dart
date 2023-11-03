import 'dart:ui';

import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/services.dart';
import 'package:untitled_rhythm_game/components/games/minigame_type.dart';
import 'package:untitled_rhythm_game/components/games/swipe/swipe_game_component.dart';
import 'package:untitled_rhythm_game/components/games/swipe/swipe_obstacle.dart';
import 'package:untitled_rhythm_game/components/mixins/level_size_aware.dart';
import 'package:untitled_rhythm_game/my_game.dart';

class ShipComponent extends SpriteComponent
    with HasGameRef<MyGame>, LevelSizeAware, CollisionCallbacks {
  /// Represents the Y placement of the ship out of the game size's full Y axis (from the top of the canvas).
  static const double hitCircleYPlacementModifier = 0.75;

  /// Distance the sprite will cover up and down.
  static const double hoverOffset = 10.0;

  late final Sprite _explosionSpriteSheet;

  MoveEffect? _evadeEffect;

  ShipComponent({
    super.position,
    super.priority,
  }) : super(anchor: Anchor.topCenter);

  Future<void> onLoad() async {
    setLevelSize();
    position = Vector2(this.levelSize.x / 2,
        this.levelSize.y * hitCircleYPlacementModifier - (hoverOffset / 2));
    size = Vector2.all(
        levelSize.x / SwipeGameComponent.numberOfColumns.toDouble() - 10);
    sprite = await Sprite.load('xwing_sprite.png');
    _explosionSpriteSheet = await Sprite.load('explosion_sprite_sheet.png');
    // Add a circular HitBox around the ship.
    add(CircleHitbox(
      radius: (size.x / 2) * 0.8,
      anchor: Anchor.center,
      position: size / 2,
    ));
    // Add a hover/floating animation to the sprite.
    add(
      MoveEffect.to(
        position + Vector2(0, hoverOffset),
        EffectController(
          duration: 0.5,
          alternate: true,
          infinite: true,
        ),
      ),
    );
    await super.onLoad();
  }

  /// Quickly move the ship to column at [columnIndex].
  void evadeTo(int columnIndex) {
    // Stop any current movement and move the the set column.
    _evadeEffect?.removeFromParent();
    add(
      _evadeEffect = MoveEffect.to(
        Vector2(
            ((columnIndex * 2) + 1) *
                (levelSize.x / (SwipeGameComponent.numberOfColumns * 2)),
            position.y),
        LinearEffectController(0.1),
      ),
    );
    // Add shifting effect to image and reset once moving completes.
    paint.imageFilter = ImageFilter.dilate(radiusX: 15, radiusY: 0);
    scale = Vector2(1.1, 1);
    _evadeEffect!.onComplete = () {
      paint.imageFilter = null;
      scale = Vector2.all(1);
      HapticFeedback.mediumImpact();
    };
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    if (other is SwipeObstacle) {
      // Check if this collision has already been handled.
      if (!other.hasCollidedWithShip) {
        other.hasCollidedWithShip = true;
        // OUCH! Big explosion!
        add(SpriteAnimationComponent(
          animation: SpriteAnimation.fromFrameData(
            _explosionSpriteSheet.image,
            SpriteAnimationData.sequenced(
              amount: 26,
              textureSize: Vector2.all(128),
              stepTime: 0.05,
              loop: false,
            ),
          ),
          size: size,
          scale: Vector2(1, -1),
          position: Vector2(0, size.y),
          removeOnFinish: true,
        ));
        HapticFeedback.heavyImpact();
        // Notify score of collision.
        gameRef.currentLevel.scoreComponent.collision(MiniGameType.swipe);
      }
    }
    super.onCollision(points, other);
  }
}
