import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class ScoreMultiplierComponent extends PositionComponent {
  /// The list of colors for each multiplier amount.
  static const List<Color> multiplierColors = [
    Colors.white,
    Colors.yellow,
    Colors.orange,
    Colors.red
  ];
  late TextComponent textComponent;
  late TextComponent textComponentOutline;

  int _multiplier = 1;

  ScoreMultiplierComponent({required Vector2 position, required Anchor anchor})
      : super(position: position, anchor: anchor);

  @override
  Future<void> onLoad() async {
    add(CircleComponent(
      radius: 100,
      position: Vector2(10, 5),
      anchor: Anchor.center,
      paint: Paint()..color = Colors.indigo.withOpacity(0.8),
    ));
    textComponent = TextComponent(
      text: _getText(1),
      textRenderer: TextPaint(style: _getTextStyle(multiplierColors[0])),
      position: Vector2(-5, -5),
      scale: Vector2.all(4),
      angle: -(2 * pi) * 0.025,
      anchor: Anchor.topRight,
    );
    textComponentOutline = TextComponent(
      text: _getText(1),
      textRenderer: TextPaint(style: _getTextStyle(Colors.black)),
      position: Vector2(5, -5),
      scale: Vector2.all(4.5),
      angle: -(2 * pi) * 0.025,
      anchor: Anchor.topRight,
    );
    add(textComponentOutline);
    add(textComponent);
    super.onLoad();
  }

  set multiplier(int multiplier) {
    if (multiplier != _multiplier) {
      // If the multiplier increased, add flashy effect.
      if (multiplier > _multiplier) {
        // TODO add a flashy effect lol.
      }
      textComponent.textRenderer =
          TextPaint(style: _getTextStyle(multiplierColors[multiplier - 1]));
      textComponent.text = _getText(multiplier);
      textComponentOutline.text = _getText(multiplier);

      _multiplier = multiplier;
    }
  }

  static TextStyle _getTextStyle(Color color) {
    return TextStyle(color: color, fontWeight: FontWeight.bold);
  }

  static String _getText(multiplier) {
    return "x$multiplier";
  }
}
