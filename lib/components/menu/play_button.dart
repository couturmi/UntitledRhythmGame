import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';

class PlayButton extends PositionComponent with Tappable {
  final Vector2 buttonSize = Vector2(200, 75);
  final Vector2 hoverOffset = Vector2(0, 10);
  late LinearEffectController hoverEffectController;
  int direction = 0;

  final Function onButtonTap;

  PlayButton({
    required this.onButtonTap,
    Vector2? position,
    double? angle,
    Anchor? anchor,
    int? priority,
  }) : super(
            position: position,
            angle: angle,
            anchor: anchor,
            priority: priority);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    size = buttonSize;
    position = position + (hoverOffset / 2);
    add(RectangleComponent(
      priority: 0,
      size: size,
      paint: Paint()..color = Colors.yellow.withOpacity(0.6),
      position: Vector2(-10, 10),
    ));
    add(RectangleComponent(
      priority: 1,
      size: size,
      paint: Paint()..color = Colors.yellow,
    ));
    add(TextComponent(
      priority: 2,
      text: "P L A Y",
      textRenderer:
          TextPaint(style: TextStyle(color: Colors.black, fontSize: 26)),
      position: buttonSize / 2,
      anchor: Anchor.center,
    ));

    // Add initial Hover Effect.
    hoverEffectController = LinearEffectController(1);
    hoverUpEffect();
  }

  void hoverUpEffect() {
    direction = 0;
    add(MoveEffect.to(position - hoverOffset, hoverEffectController));
  }

  void hoverDownEffect() {
    direction = 1;
    add(MoveEffect.to(position + hoverOffset, hoverEffectController));
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (hoverEffectController.completed) {
      hoverEffectController.setToStart();
      if (direction == 0) {
        hoverDownEffect();
      } else {
        hoverUpEffect();
      }
    }
  }

  @override
  bool onTapDown(TapDownInfo info) {
    super.onTapDown(info);
    scale = scale * 0.9;
    return true;
  }

  @override
  bool onTapUp(TapUpInfo info) {
    super.onTapUp(info);
    this.onButtonTap();
    return true;
  }
}
