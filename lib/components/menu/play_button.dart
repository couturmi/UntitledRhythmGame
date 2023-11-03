import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class PlayButton extends PositionComponent with TapCallbacks {
  final Vector2 buttonSize = Vector2(200, 75);
  final Vector2 hoverOffset = Vector2(0, 10);

  final Function onButtonTap;
  final String buttonText;

  PlayButton({
    required this.onButtonTap,
    Vector2? position,
    double? angle,
    Anchor? anchor,
    int? priority,
    this.buttonText = "P L A Y",
  }) : super(
            position: position,
            angle: angle,
            anchor: anchor,
            priority: priority);

  @override
  Future<void> onLoad() async {
    super.onLoad();
    size = buttonSize;
    position = position;
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
      text: buttonText,
      textRenderer:
          TextPaint(style: TextStyle(color: Colors.black, fontSize: 26)),
      position: buttonSize / 2,
      anchor: Anchor.center,
    ));

    // Add Hover Effect.
    add(
      MoveEffect.to(
        position - hoverOffset,
        EffectController(
          duration: 1,
          alternate: true,
          infinite: true,
        ),
      ),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    scale = scale * 0.9;
  }

  @override
  void onTapUp(TapUpEvent event) {
    scale = scale / 0.9;
    this.onButtonTap();
  }
}
