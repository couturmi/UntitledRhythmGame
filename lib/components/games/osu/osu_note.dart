import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled_rhythm_game/my_game.dart';
import 'package:untitled_rhythm_game/song_level_component.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class OsuNote extends PositionComponent with HasGameRef<MyGame> {
  /// Scale of the timing ring when the note is created.
  static const double timingRingStartingScale = 2.5;

  /// Represents how close the timing ring is to completion to
  /// consider a note hit successful.
  static const double timingRingHitAllowanceModifier = 0.2;

  /// Current color of this note group. This value updates when the next note
  /// with a label "1" is added.
  static int currentNoteColorIndex = -1;

  /// Time (in seconds) that this note was expected to be loaded.
  final double expectedTimeOfStart;

  /// Time (in microseconds) of a single beat.
  final int beatInterval;

  /// Max time (in seconds) that the note is able to be tapped.
  final double timeNoteIsInQueue;

  /// Number label displayed on the note.
  final String label;

  /// Ring used to determine the timing of the note.
  late final CircleComponent _timingRing;

  /// Color of this note.
  late final Color noteColor;

  late final CircleComponent _noteFill;
  late final CircleComponent _noteBorder;
  late final SpriteComponent _sprite;

  OsuNote({
    required double diameter,
    super.position,
    super.anchor,
    super.priority,
    required this.expectedTimeOfStart,
    required this.timeNoteIsInQueue,
    required this.beatInterval,
    required this.label,
  }) : super(
          size: Vector2.all(diameter),
        ) {
    // If this is a new group, update the color index.
    if (label == "1") {
      currentNoteColorIndex++;
      if (currentNoteColorIndex > _noteColors.length - 1) {
        currentNoteColorIndex = 0;
      }
    }
    noteColor = _noteColors[currentNoteColorIndex];
  }

  /// Returns the list of all note color options.
  List<Color> get _noteColors => [
        Colors.indigo.shade900,
        Colors.red.shade900,
        Colors.green.shade700,
        Colors.pinkAccent.shade200,
        Colors.orange.shade700,
        Colors.amber,
        Colors.purple,
      ];

  double get currentTimingOfNote =>
      gameRef.currentLevel.songTime - expectedTimeOfStart;

  Future<void> onLoad() async {
    add(_noteFill = CircleComponent(
      paint: Paint()..color = noteColor,
      radius: size.x / 2,
      position: size / 2,
      anchor: Anchor.center,
      priority: 0,
    ));
    add(_sprite = SpriteComponent(
      sprite: await Sprite.load('osu_note.png'),
      size: size,
      position: size / 2,
      anchor: Anchor.center,
      priority: 1,
    ));
    add(_noteBorder = CircleComponent(
      paint: Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
      radius: size.x / 2,
      position: size / 2,
      anchor: Anchor.center,
      priority: 2,
    ));
    add(TextComponent(
      text: label,
      position: size / 2,
      anchor: Anchor.center,
      textRenderer: TextPaint(
          style: TextStyle(
        color: Colors.white,
        fontSize: 60,
        fontFamily: 'Courier',
        fontWeight: FontWeight.bold,
      )),
      priority: 2,
    ));
    // Set opacity to hidden, and add animation to fade in.
    // Note: Both the timing ring and the text component do not fade in.
    _noteFill.setOpacity(0);
    _noteBorder.setOpacity(0);
    _sprite.setOpacity(0);
    double currentTiming = currentTimingOfNote;
    _noteFill.add(OpacityEffect.fadeIn(LinearEffectController(
        microsecondsToSeconds(beatInterval - currentTiming))));
    _noteBorder.add(OpacityEffect.fadeIn(LinearEffectController(
        microsecondsToSeconds(beatInterval - currentTiming))));
    _sprite.add(OpacityEffect.fadeIn(LinearEffectController(
        microsecondsToSeconds(beatInterval - currentTiming))));
    // Create timing ring component and add scaling effect.
    _timingRing = CircleComponent(
      radius: size.x / 2,
      position: size / 2,
      anchor: Anchor.center,
      paint: Paint()
        ..color = noteColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
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
    _sprite.paint
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
    _sprite.paint
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30)
      ..colorFilter =
          ColorFilter.mode(Colors.red.withOpacity(0.5), BlendMode.overlay);
    // Add a fade out and fall effect.
    add(MoveEffect.by(Vector2(0, 25), LinearEffectController(0.2)));
    _noteFill.add(OpacityEffect.fadeOut(LinearEffectController(0.2)));
    _noteBorder.add(OpacityEffect.fadeOut(LinearEffectController(0.2)));
    _sprite.add(OpacityEffect.fadeOut(LinearEffectController(0.2)));
    // remove the note after a short time of displaying.
    add(RemoveEffect(delay: 0.2));
  }
}
