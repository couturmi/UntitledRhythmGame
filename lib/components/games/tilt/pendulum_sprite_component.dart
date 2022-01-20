import 'package:flame/components.dart';

class PendulumSpriteComponent extends SpriteComponent {
  static const double defaultRadius = 128.0;

  PendulumSpriteComponent({required Vector2 position, Vector2? size})
      : super(
            position: position,
            size: size ?? Vector2.all(defaultRadius),
            anchor: Anchor.bottomCenter);

  Future<void> onLoad() async {
    sprite = await Sprite.load("pendulum.png");
    await super.onLoad();
  }
}
