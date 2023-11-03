import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';
import 'package:untitled_rhythm_game/components/mixins/level_size_aware.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';
import 'package:untitled_rhythm_game/my_game.dart';

class BucketComponent extends PositionComponent
    with HasGameRef<MyGame>, LevelSizeAware, DragCallbacks {
  /// Represents the Y placement of the hit circle out of the game size's full Y axis (from the top of the canvas).
  static const double hitCircleYPlacementModifier = 0.2;

  /// The width of the bucket/catcher.
  static const double bucketWidth = 180.0;

  /// Distance the sprite will cover up and down.
  static const double hoverOffset = 10.0;

  late final PositionComponent _sprite;

  BucketComponent({super.priority}) : super(anchor: Anchor.topCenter);

  Future<void> onLoad() async {
    setLevelSize();
    position = Vector2(levelSize.x / 2, 0);
    // Note that "size" here refers to the size of the hit/drag box that your finger can tap.
    size = Vector2(bucketWidth * 1.5, levelSize.y);
    await loadSprite();
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

  Future<void> loadSprite() async {
    // Check if sprite replacement exists.
    final SpriteReplacementModel? spriteModel =
        gameRef.currentLevel.beatMap.spriteReplacements["slide_bucket"];
    // Check if sprite is a GIF/SpriteSheet.
    if (spriteModel != null && spriteModel.frames > 0) {
      Sprite marioSpriteSheet = await Sprite.load(spriteModel.path);
      add(_sprite = SpriteAnimationComponent(
        animation: SpriteAnimation.fromFrameData(
          marioSpriteSheet.image,
          SpriteAnimationData.sequenced(
            amount: spriteModel.frames,
            textureSize: Vector2(spriteModel.pixelsX, spriteModel.pixelsY),
            stepTime: spriteModel.stepTime,
            loop: true,
          ),
        ),
        anchor: Anchor.center,
        size: Vector2.all(bucketWidth),
        position: Vector2(bucketWidth / 2,
            levelSize.y * hitCircleYPlacementModifier - (hoverOffset / 2)),
        removeOnFinish: false,
      ));
    }
    // Otherwise it is just a sprite image.
    else {
      add(_sprite = SpriteComponent(
        sprite: await Sprite.load(spriteModel?.path ?? "skydiver.png"),
        anchor: Anchor.center,
        size: Vector2.all(bucketWidth),
        position: Vector2(bucketWidth / 2,
            levelSize.y * hitCircleYPlacementModifier - (hoverOffset / 2)),
      ));
    }
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
        newXPosition > levelSize.x - (bucketWidth / 4)) {
      return true;
    }
    position = Vector2(newXPosition, position.y);
    return true;
  }
}
