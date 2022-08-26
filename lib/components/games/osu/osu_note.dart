import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled_rhythm_game/my_game.dart';
import 'package:untitled_rhythm_game/song_level_component.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class OsuNote extends SpriteComponent with HasGameRef<MyGame> {
  /// Scale of the timing ring when the note is created.
  static const double timingRingStartingScale = 2.5;

  /// Represents how close the timing ring is to completion to
  /// consider a note hit successful.
  static const double timingRingHitAllowanceModifier = 0.15;

  /// Time (in seconds) that this note was expected to be loaded.
  final double expectedTimeOfStart;

  /// Time (in microseconds) of a single beat.
  final int beatInterval;

  /// Max time (in seconds) that the note is able to be tapped.
  final double timeNoteIsInQueue;

  /// Ring used to determine the timing of the note.
  late final CircleComponent _timingRing;

  OsuNote({
    required double diameter,
    required Vector2 position,
    required Anchor anchor,
    required this.expectedTimeOfStart,
    required this.timeNoteIsInQueue,
    required this.beatInterval,
  }) : super(
          size: Vector2.all(diameter),
          position: position,
          anchor: anchor,
        );

  double get currentTimingOfNote =>
      gameRef.currentLevel.songTime - expectedTimeOfStart;

  Future<void> onLoad() async {
    sprite = await Sprite.load('osu_note.png');
    setOpacity(0);
    _timingRing = CircleComponent(
      radius: size.x / 2,
      position: size / 2,
      anchor: Anchor.center,
      paint: Paint()
        ..color = Colors.yellow
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    double currentTiming = currentTimingOfNote;
    final double currentProgress = currentTiming / timeNoteIsInQueue;
    _timingRing.scale = Vector2.all(
      timingRingStartingScale -
          (min(currentProgress, 1) * timingRingStartingScale),
    );
    add(_timingRing);
    _timingRing.add(
      ScaleEffect.to(
          Vector2.all(1),
          LinearEffectController(microsecondsToSeconds(
              (beatInterval * SongLevelComponent.INTERVAL_TIMING_MULTIPLIER) -
                  currentTiming))),
    );
    add(OpacityEffect.fadeIn(LinearEffectController(
        microsecondsToSeconds(beatInterval - currentTiming))));
    await super.onLoad();
  }

  /// Check if the current hit timing would result in a successful hit.
  bool isHitTimingSuccessful() {
    return _timingRing.scale.x <= 1 + timingRingHitAllowanceModifier;
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
    add(RemoveEffect(delay: 0.1));
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
    add(MoveEffect.by(Vector2(0, 25), LinearEffectController(0.2)));
    add(OpacityEffect.fadeOut(LinearEffectController(0.2)));
    // remove the note after a short time of displaying.
    add(RemoveEffect(delay: 0.2));
  }
}
