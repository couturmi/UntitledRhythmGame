import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class LevelLoadingComponent extends PositionComponent with HasGameRef {
  late final SpriteComponent _spinnerSprite;
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;
    final double spriteSize = game.size.y / 8;
    final double yOffset = -spriteSize / 2;
    position = game.size / 2 + Vector2(0, yOffset);
    add(SpriteComponent(
      priority: 0,
      sprite: await Sprite.load("off_beat_logo_B.png"),
      size: Vector2.all(spriteSize),
      anchor: Anchor.center,
      position: Vector2.all(spriteSize / 4),
    ));
    _spinnerSprite = SpriteComponent(
      priority: 1,
      sprite: await Sprite.load("off_beat_logo_O.png"),
      size: Vector2.all(spriteSize),
      anchor: Anchor.center,
      position: Vector2.all(-spriteSize / 4),
    );
    add(_spinnerSprite);
    add(TextComponent(
      text: "Loading...",
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.yellow,
          fontSize: 12,
        ),
      ),
      scale: Vector2.all(2),
      anchor: Anchor.center,
      position: Vector2(0, spriteSize),
    ));
  }

  @override
  void update(double dt) {
    _spinnerSprite.angle += 3 * dt;
    super.update(dt);
  }
}
