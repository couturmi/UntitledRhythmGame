import 'dart:async' as Async;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SlideNote extends SpriteComponent {
  SlideNote({
    required double diameter,
    required Vector2 position,
    required Anchor anchor,
  }) : super(
          size: Vector2.all(diameter),
          position: position,
          anchor: anchor,
        );

  Future<void> onLoad() async {
    sprite = await Sprite.load('osu_note.png');
    await super.onLoad();
  }

  /// Called if a note is tapped and cleared successfully.
  void hit() {
    // Remove all active effects.
    children.removeWhere((c) => c is Effect);
    // update with golden glow.
    paint
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30)
      ..colorFilter = ColorFilter.mode(Colors.greenAccent, BlendMode.overlay);
    // Provide haptic feedback.
    HapticFeedback.lightImpact();
    // remove the note after a short time of displaying.
    Async.Timer(Duration(milliseconds: 100), () {
      parent?.remove(this);
    });
  }

  /// Called if a note is missed completely and the player has horribly failed.
  void missed() {
    // Remove all active effects.
    children.removeWhere((c) => c is Effect);
    // update with red glow.
    paint
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30)
      ..colorFilter =
          ColorFilter.mode(Colors.red.withOpacity(0.5), BlendMode.overlay);
    // Add a fade out and fall effect.
    add(OpacityEffect.fadeOut(LinearEffectController(0.2)));
    // remove the note after a short time of displaying.
    Async.Timer(Duration(milliseconds: 200), () {
      parent?.remove(this);
    });
  }
}
