import 'package:flame/components.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';
import 'package:untitled_rhythm_game/my_game.dart';

class PendulumSpriteComponent extends PositionComponent
    with HasGameRef<MyGame> {
  final double hitCircleCenterHeight;
  final double hitCircleDiameter;

  PendulumSpriteComponent(
      {required this.hitCircleCenterHeight, required this.hitCircleDiameter})
      : super(anchor: Anchor.bottomCenter);

  Future<void> onLoad() async {
    // Check if sprite replacements exist.
    final SpriteReplacementModel? gloveSpriteModel =
        gameRef.currentLevel.beatMap.spriteReplacements["tilt_glove"];
    // Check if sprite replacements exist.
    final SpriteReplacementModel? armSpriteModel =
        gameRef.currentLevel.beatMap.spriteReplacements["tilt_arm"];
    await add(SpriteComponent(
      priority: 1,
      sprite: await Sprite.load(gloveSpriteModel?.path ?? "boxing_glove.png"),
      size: Vector2.all(hitCircleDiameter),
      anchor: Anchor.center,
      position: Vector2(0, -hitCircleCenterHeight),
    ));
    await add(SpriteComponent(
      priority: 0,
      sprite: await Sprite.load(armSpriteModel?.path ?? "arm.png"),
      size: Vector2(
          hitCircleCenterHeight * 0.514, // keep aspect ratio of png.
          hitCircleCenterHeight),
      anchor: Anchor.bottomCenter,
      position: Vector2(0, (hitCircleDiameter / 4)),
    ));
    await super.onLoad();
  }
}
