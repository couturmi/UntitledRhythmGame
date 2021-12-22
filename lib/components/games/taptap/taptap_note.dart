import 'dart:async' as Async;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class TapTapNote extends SpriteComponent {
  TapTapNote({
    required double diameter,
    required Vector2 position,
    required Anchor anchor,
  }) : super(
          size: Vector2.all(diameter),
          position: position,
          anchor: anchor,
        );

  Future<void> onLoad() async {
    sprite = await Sprite.load('taptap_note.png');
    await super.onLoad();
  }

  /// Called if a note is tapped and cleared successfully.
  void pop() {
    paint
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 35)
      ..colorFilter = ColorFilter.mode(Colors.amberAccent, BlendMode.overlay);
    Async.Timer(Duration(milliseconds: 100), () {
      parent?.remove(this);
    });
  }
}
