import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/experimental.dart';
import 'package:flutter/services.dart';
import 'package:untitled_rhythm_game/components/mixins/game_size_aware.dart';
import 'package:untitled_rhythm_game/my_game.dart';

class BucketComponent extends PositionComponent
    with GameSizeAware, HasGameRef<MyGame>, DragCallbacks {
  /// Represents the Y placement of the hit circle out of the game size's full Y axis (from the top of the canvas).
  static const double hitCircleYPlacementModifier = 0.2;

  /// The width of the bucket/catcher.
  static const double bucketWidth = 180.0;

  /// Distance the sprite will cover up and down.
  static const double hoverOffset = 10.0;

  late final SpriteComponent _sprite;

  BucketComponent({super.priority}) : super(anchor: Anchor.topCenter);

  Future<void> onLoad() async {
    position = Vector2(gameSize.x / 2, 0);
    // Note that "size" here refers to the size of the hit/drag box that your finger can tap.
    size = Vector2(bucketWidth * 1.5, gameSize.y);
    add(_sprite = SpriteComponent(
      sprite: await Sprite.load("skydiver.png"),
      size: Vector2.all(bucketWidth),
      anchor: Anchor.center,
      position: Vector2(bucketWidth / 2,
          gameSize.y * hitCircleYPlacementModifier - (hoverOffset / 2)),
    ));
    // Add a hover/floating animation to the sprite.
    _sprite.add(
      MoveEffect.to(
        _sprite.position + Vector2(0, hoverOffset),
        EffectController(
          duration: 0.5,
          alternate: true,
          infinite: true,
        ),
      ),
    );
    await super.onLoad();
  }

  @override
  bool onDragUpdate(DragUpdateEvent event) {
    double dragAmount = event.delta.y;
    if (gameRef.currentLevel.currentLevelOrientation ==
        DeviceOrientation.landscapeRight) {
      dragAmount *= -1;
    }
    double newXPosition = position.x + dragAmount;
    if (newXPosition < (bucketWidth / 4) ||
        newXPosition > gameSize.x - (bucketWidth / 4)) {
      return true;
    }
    position = Vector2(newXPosition, position.y);
    return true;
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    this.onResize(Vector2(gameSize.y, gameSize.x));
  }
}
