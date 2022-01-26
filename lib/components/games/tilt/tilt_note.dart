import 'dart:async' as Async;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TiltNote extends SpriteComponent {
  TiltNote({
    required double diameter,
    required Vector2 position,
    required Anchor anchor,
  }) : super(
          size: Vector2.all(diameter),
          position: position,
          anchor: anchor,
        );

  Future<void> onLoad() async {
    sprite = await Sprite.load('tilt_note.png');
    await super.onLoad();
  }

  /// Called if a note is hit and cleared successfully.
  void hit(int column) {
    // clearing children will stop all active effects.
    children.clear();
    int shootDirection = column == 0 ? -1 : 1;
    add(MoveEffect.by(
        Vector2(shootDirection * 100, -200), LinearEffectController(0.15)));
    // remove the note after a short time of displaying.
    Async.Timer(Duration(milliseconds: 150), () {
      parent?.remove(this);
    });
    HapticFeedback.lightImpact();
  }

  /// Called if a note is missed completely and the player has horribly failed.
  void missed() {
    // clearing children will stop all active effects.
    children.clear();
    // update with red glow.
    paint
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30)
      ..colorFilter =
          ColorFilter.mode(Colors.red.withOpacity(0.5), BlendMode.overlay);
    // Add a fade out and fall effect.
    add(MoveEffect.by(Vector2(0, 25), LinearEffectController(0.2)));
    add(OpacityEffect.fadeOut(LinearEffectController(0.2)));
    // remove the note after a short time of displaying.
    Async.Timer(Duration(milliseconds: 200), () {
      parent?.remove(this);
    });
  }
}
