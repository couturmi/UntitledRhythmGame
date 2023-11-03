import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class PauseMenuButton extends PositionComponent with TapCallbacks {
  final Vector2 buttonSize = Vector2(150, 30);
  final Vector2 hoverOffset = Vector2(0, 10);

  final Function onButtonTap;
  final String buttonText;

  late final RectangleComponent _buttonBackground;

  PauseMenuButton({
    required this.buttonText,
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
    size = buttonSize;
    position = position;
    add(_buttonBackground = RectangleComponent(
      priority: 1,
      size: size,
      paint: Paint()..color = Colors.yellow,
    ));
    add(TextComponent(
      priority: 2,
      text: buttonText,
      textRenderer:
          TextPaint(style: TextStyle(color: Colors.black, fontSize: 16)),
      position: buttonSize / 2,
      anchor: Anchor.center,
    ));
    super.onLoad();
  }

  @override
  void onTapDown(TapDownEvent event) {
    _buttonBackground.paint.color = Colors.yellow.withOpacity(0.6);
  }

  @override
  void onTapUp(TapUpEvent event) {
    _buttonBackground.paint.color = Colors.yellow;
    this.onButtonTap();
  }
}
