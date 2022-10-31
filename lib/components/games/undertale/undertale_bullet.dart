import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';

class UndertaleBullet extends PositionComponent {
  late final SpriteComponent _sprite;

  /// True when the player has collided with this obstacle.
  bool hasCollidedWithPlayer = false;

  UndertaleBullet({
    super.priority,
    super.position,
    super.size,
    super.anchor,
  });

  @override
  Future<void> onLoad() async {
    add(_sprite = SpriteComponent(
      priority: 0,
      sprite: await Sprite.load("bullet_1.png"),
      size: size,
      anchor: Anchor.center,
      position: size / 2,
    ));
    add(RectangleHitbox(
      size: Vector2(size.x * 0.5, size.y),
      anchor: Anchor.center,
      position: size / 2,
    )..collisionType = CollisionType.passive);
    super.onLoad();
  }

  /// Hide the bullet sprite via fade out.
  void fadeOut(double duration) {
    _sprite.add(OpacityEffect.fadeOut(LinearEffectController(duration)));
  }

  void collisionOccurred() {
    hasCollidedWithPlayer = true;
    // Hide the bullet from view.
    _sprite.setOpacity(0);
  }
}
