import 'dart:async' as Async;
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled_rhythm_game/song_level_component.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class OsuNote extends SpriteComponent {
  /// Scale of the timing ring when the note is created.
  static const double timingRingStartingScale = 1.75;

  /// Represents how close the timing ring is to completion to
  /// consider a note hit successful.
  static const double timingRingHitAllowanceModifier = 0.15;

  /// Ring used to determine the timing of the note.
  late final CircleComponent _timingRing;

  OsuNote({
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
    setOpacity(0);
    _timingRing = CircleComponent(
      radius: size.x / 2,
      position: size / 2,
      anchor: Anchor.center,
      scale: Vector2.all(timingRingStartingScale),
      paint: Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    await add(_timingRing);
    await super.onLoad();
  }

  /// Effect on the note that lets the user know the timing to tap it.
  void startTimingEffect(int beatInterval) {
    _timingRing.add(
      ScaleEffect.to(
          Vector2.all(1),
          LinearEffectController(microsecondsToSeconds(
              beatInterval * SongLevelComponent.INTERVAL_TIMING_MULTIPLIER))),
    );
    add(OpacityEffect.fadeIn(
        LinearEffectController(microsecondsToSeconds(beatInterval))));
  }

  /// Check if the current hit timing would result in a successful hit.
  bool isHitTimingSuccessful() {
    return _timingRing.scale.x <= 1 + timingRingHitAllowanceModifier;
  }

  /// Called if a note is tapped and cleared successfully.
  void hit() {
    // clearing children will stop all active effects.
    children.clear();
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
