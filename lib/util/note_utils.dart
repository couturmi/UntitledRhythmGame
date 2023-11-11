import 'package:flame/components.dart';
import 'package:flutter/material.dart';

extension NoteGlow on SpriteComponent {
  void addNoteGlow({Color? color}) {
    paint
      ..colorFilter = ColorFilter.mode(
          (color ?? Colors.greenAccent.shade700).withOpacity(0.3),
          BlendMode.srcATop);
    _addGlow(color ?? Colors.greenAccent);
  }

  void addNegativeNoteGlow() {
    paint
      ..colorFilter = ColorFilter.mode(
          Colors.red.shade700.withOpacity(0.7), BlendMode.srcATop);
    _addGlow(Colors.red);
  }

  void _addGlow(Color color) {
    add(CircleComponent(
      anchor: Anchor.center,
      position: this.size / 2,
      radius: this.size.x * 0.6,
      scale: this.scale,
      paint: Paint()
        ..color = color.withOpacity(0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30),
    ));
  }
}
