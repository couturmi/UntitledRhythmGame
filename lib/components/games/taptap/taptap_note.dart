import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/my_game.dart';

class TapTapNote extends SpriteComponent with HasGameRef<MyGame> {
  /// Time (in seconds) that this note was expected to be loaded.
  final double expectedTimeOfStart;

  /// Max distance that the note travels before automatic removal.
  final double fullNoteTravelDistance;

  /// Max time (in seconds) that the note is able to be tapped.
  final double timeNoteIsInQueue;

  /// Max time (in seconds) that the note is displayed before automatic removal.
  final double timeNoteIsVisible;

  bool isRemovingFromParent = false;

  TapTapNote({
    required double diameter,
    required Vector2 position,
    required Anchor anchor,
    required this.expectedTimeOfStart,
    required this.fullNoteTravelDistance,
    required this.timeNoteIsInQueue,
    required this.timeNoteIsVisible,
  }) : super(
          size: Vector2.all(diameter),
          position: position,
          anchor: anchor,
        );

  double get currentTimingOfNote =>
      gameRef.currentLevel.songTime - expectedTimeOfStart;

  Future<void> onLoad() async {
    sprite = await Sprite.load('taptap_note.png');
    double currentTiming = currentTimingOfNote;
    final double currentProgress = currentTiming / timeNoteIsVisible;
    position.y = min(currentProgress, 1) * fullNoteTravelDistance;
    // Add Effect to move to the end location.
    add(MoveEffect.to(Vector2(0, fullNoteTravelDistance),
        LinearEffectController(timeNoteIsVisible - currentTiming)));
    await super.onLoad();
  }

  @override
  void update(double dt) {
    // Check if the note should be removed from the scene.
    if (currentTimingOfNote >= timeNoteIsVisible && !isRemovingFromParent) {
      _missed();
    }
    super.update(dt);
  }

  /// Called if a note is tapped and cleared successfully.
  void hit() {
    isRemovingFromParent = true;
    // Remove all active effects.
    children.removeWhere((c) => c is Effect);
    // update with golden glow.
    paint
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30)
      ..colorFilter = ColorFilter.mode(Colors.amberAccent, BlendMode.overlay);
    // remove the note after a short time of displaying.
    add(RemoveEffect(delay: 0.1));
  }

  /// Called if a note is missed completely and the player has horribly failed.
  void _missed() {
    isRemovingFromParent = true;
    // update with red glow.
    paint
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 50)
      ..colorFilter = ColorFilter.mode(Colors.red, BlendMode.overlay);
    // remove the note after a short time of displaying.
    add(RemoveEffect(delay: 0.05));
  }
}
