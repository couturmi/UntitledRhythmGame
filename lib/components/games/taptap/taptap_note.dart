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
  void hit() {
    // clearing children will stop all active effects.
    children.clear();
    // update with golden glow.
    paint
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30)
      ..colorFilter = ColorFilter.mode(Colors.amberAccent, BlendMode.overlay);
    // remove the note after a short time of displaying.
    Async.Timer(Duration(milliseconds: 100), () {
      parent?.remove(this);
    });
  }

  /// Called if a note is missed completely and the player has horribly failed.
  void missed() {
    // update with red glow.
    paint
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 50)
      ..colorFilter = ColorFilter.mode(Colors.red, BlendMode.overlay);
    // remove the note after a short time of displaying.
    Async.Timer(Duration(milliseconds: 50), () {
      parent?.remove(this);
    });
  }
}
