import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/services.dart';
import 'package:untitled_rhythm_game/components/games/minigame_type.dart';
import 'package:untitled_rhythm_game/components/games/undertale/undertale_bullet.dart';
import 'package:untitled_rhythm_game/my_game.dart';

class UndertalePlayer extends PositionComponent
    with HasGameRef<MyGame>, CollisionCallbacks {
  late final SpriteComponent _playerSprite;

  UndertalePlayer({super.size, super.position, super.anchor});

  @override
  Future<void> onLoad() async {
    add(_playerSprite = SpriteComponent(
      sprite: await Sprite.load('undertale_heart_sprite.png'),
      size: size,
    ));
    // Add a circular HitBox around the player.
    add(CircleHitbox(
      radius: size.x / 2,
      anchor: Anchor.center,
      position: size / 2,
    ));
    super.onLoad();
  }

  @override
  void onCollision(Set<Vector2> points, PositionComponent other) {
    if (other is UndertaleBullet) {
      // Check if this collision has already been handled.
      if (!other.hasCollidedWithPlayer) {
        other.collisionOccurred();
        // OUCH! I've been hit!! Add blinking effect.
        _playerSprite.add(OpacityEffect.to(
          0,
          SequenceEffectController([
            LinearEffectController(0.15),
            ReverseLinearEffectController(0.15),
            LinearEffectController(0.15),
            ReverseLinearEffectController(0.15),
            LinearEffectController(0.15),
            ReverseLinearEffectController(0.15),
          ]),
        ));
        // TODO add sound effect?
        HapticFeedback.heavyImpact();
        // Notify score of collision.
        gameRef.currentLevel.scoreComponent.collision(MiniGameType.undertale);
      }
    }
    super.onCollision(points, other);
  }
}
