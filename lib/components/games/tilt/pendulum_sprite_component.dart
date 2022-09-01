import 'package:flame/components.dart';

class PendulumSpriteComponent extends PositionComponent {
  final double hitCircleCenterHeight;
  final double hitCircleDiameter;

  PendulumSpriteComponent(
      {required this.hitCircleCenterHeight, required this.hitCircleDiameter})
      : super(anchor: Anchor.bottomCenter);

  Future<void> onLoad() async {
    await add(SpriteComponent(
      priority: 1,
      sprite: await Sprite.load("boxing_glove.png"),
      size: Vector2.all(hitCircleDiameter),
      anchor: Anchor.center,
      position: Vector2(0, -hitCircleCenterHeight),
    ));
    await add(SpriteComponent(
      priority: 0,
      sprite: await Sprite.load("arm.png"),
      size: Vector2(
          hitCircleCenterHeight * 0.514, // keep aspect ratio of png.
          hitCircleCenterHeight),
      anchor: Anchor.bottomCenter,
      position: Vector2(0, (hitCircleDiameter / 4)),
    ));
    await super.onLoad();
  }
}
