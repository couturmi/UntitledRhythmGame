import 'package:flame/components.dart';

class PendulumSpriteComponent extends PositionComponent {
  final double hitCircleCenterHeight;
  final double hitCircleDiameter;

  PendulumSpriteComponent(
      {required this.hitCircleCenterHeight, required this.hitCircleDiameter})
      : super(anchor: Anchor.bottomCenter);

  Future<void> onLoad() async {
    await add(RectangleComponent(
      size: Vector2(10, hitCircleCenterHeight),
      anchor: Anchor.bottomCenter,
    ));
    await add(SpriteComponent(
      sprite: await Sprite.load("boxing_glove.png"),
      size: Vector2.all(hitCircleDiameter),
      anchor: Anchor.center,
      position: Vector2(0, -hitCircleCenterHeight),
    ));
    await super.onLoad();
  }
}
