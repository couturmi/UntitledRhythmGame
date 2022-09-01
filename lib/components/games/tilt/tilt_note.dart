import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled_rhythm_game/my_game.dart';

class TiltNote extends SpriteComponent with HasGameRef<MyGame> {
  static const int numberOfBoxerAssets = 2;

  final int columnIndex;

  /// Time (in seconds) that this note was expected to be loaded.
  final double expectedTimeOfStart;

  /// Max distance that the note travels before automatic removal.
  final double fullNoteTravelDistance;

  /// Max time (in seconds) that the note is displayed before automatic removal.
  final double timeNoteIsVisible;

  late final Sprite _secondarySprite;

  bool isRemovingFromParent = false;

  TiltNote({
    required double diameter,
    super.position,
    super.anchor,
    super.priority,
    required this.columnIndex,
    required this.expectedTimeOfStart,
    required this.fullNoteTravelDistance,
    required this.timeNoteIsVisible,
  }) : super(
          size: Vector2.all(diameter),
        );

  double get currentTimingOfNote =>
      gameRef.currentLevel.songTime - expectedTimeOfStart;

  Future<void> onLoad() async {
    sprite = await Sprite.load('boxer${columnIndex + 1}.png');
    _secondarySprite = await Sprite.load('boxer${columnIndex + 1}_punched.png');
    double currentTiming = currentTimingOfNote;
    final double currentProgress = currentTiming / timeNoteIsVisible;
    position.y = min(currentProgress, 1) * fullNoteTravelDistance;
    add(MoveEffect.to(Vector2(size.x / 2, fullNoteTravelDistance),
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

  /// Called if a note is hit and cleared successfully.
  void hit(int column) {
    isRemovingFromParent = true;
    int shootDirection = column == 0 ? -1 : 1;
    // Replace sprite and set direction.
    sprite = _secondarySprite;
    scale = Vector2(shootDirection.toDouble(), 1);
    // Remove all active effects.
    children.removeWhere((c) => c is Effect);
    add(MoveEffect.by(
        Vector2(shootDirection * 200, -200), LinearEffectController(1.0)));
    // remove the note after a short time of displaying.
    add(RemoveEffect(delay: 1.0));
    HapticFeedback.mediumImpact();
  }

  /// Called if a note is missed completely and the player has horribly failed.
  void _missed() {
    isRemovingFromParent = true;
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
