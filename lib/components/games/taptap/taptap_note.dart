import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/games/minigame_type.dart';
import 'package:untitled_rhythm_game/components/games/taptap/taptap_column.dart';
import 'package:untitled_rhythm_game/components/games/taptap/taptap_note_bar.dart';
import 'package:untitled_rhythm_game/components/mixins/level_size_aware.dart';
import 'package:untitled_rhythm_game/off_beat_game.dart';
import 'package:untitled_rhythm_game/components/level/song_level_component.dart';

class TapTapNote extends PositionComponent
    with HasGameRef<OffBeatGame>, LevelSizeAware {
  /// Duration (in percentage of an interval) that this note should be held after being tapped.
  /// A note with no holding will have a [holdDuration] of 0;
  final double holdDuration;

  /// Time (in seconds) of a single beat.
  final double interval;

  /// Time (in seconds) that this note was expected to be loaded.
  final double expectedTimeOfStart;

  /// Represents the Y placement of the hit circle out of the game size's full Y axis.
  late final double hitCircleYPlacementModifier;

  /// Represents the exact song time (in seconds) that the score was updated for holding the note.
  double? lastPointUpdateTime;

  bool isRemovingFromParent = false;

  late final SpriteComponent _sprite;
  TapTapNoteBar? _noteBar;

  TapTapNote({
    required double diameter,
    super.position,
    super.anchor,
    super.priority,
    required this.holdDuration,
    required this.interval,
    required this.expectedTimeOfStart,
    required this.hitCircleYPlacementModifier,
  }) : super(
          size: Vector2.all(diameter),
        );

  double get currentTimingOfNote =>
      gameRef.currentLevel.songTime - expectedTimeOfStart;

  /// Relevant to held notes only. Represents the exact time the note is expected to finish.
  double get expectedTimeOfFinish =>
      expectedTimeOfStart +
      ((holdDuration + SongLevelComponent.INTERVAL_TIMING_MULTIPLIER) *
          interval);

  /// Max distance that the note travels before automatic removal.
  double get fullNoteTravelDistance =>
      levelSize.y * (TapTapColumn.noteMaxBoundaryModifier) +
      // For non-holdable notes, below will return +0.
      (holdDuration *
          (levelSize.y *
              TapTapColumn.noteMaxBoundaryModifier /
              SongLevelComponent.INTERVAL_TIMING_MULTIPLIER));

  /// Max time (in seconds) that the note is displayed before automatic removal.
  double get timeNoteIsVisible =>
      _timeForNoteToTravel(TapTapColumn.noteMaxBoundaryModifier, interval) +
      // For non-holdable notes, below will return +0.
      (holdDuration *
          (_timeForNoteToTravel(
                  TapTapColumn.noteMaxBoundaryModifier, interval) /
              SongLevelComponent.INTERVAL_TIMING_MULTIPLIER));

  /// Time (in seconds) that the note is displayed before it leaves the hittable notes queue.
  double get timeNoteIsInQueue => _timeForNoteToTravel(
      hitCircleYPlacementModifier + TapTapColumn.hitCircleAllowanceModifier,
      interval);

  /// Time (in seconds) that the note is displayed before it becomes tappable.
  double get timeUntilNoteCanBeHit => _timeForNoteToTravel(
      hitCircleYPlacementModifier - TapTapColumn.hitCircleAllowanceModifier,
      interval);

  /// Calculates the time (in seconds) it should take for a note to travel [yPercentageTarget] percent of the Y-Axis.
  ///
  /// [yPercentageTarget] : percentage of the Y-axis size that the note will have travelled.
  /// [beatInterval] : time it takes for a single beat to complete, in seconds.
  double _timeForNoteToTravel(double yPercentageTarget, double beatInterval) {
    return ((yPercentageTarget) *
            beatInterval *
            SongLevelComponent.INTERVAL_TIMING_MULTIPLIER) /
        hitCircleYPlacementModifier;
  }

  Future<void> onLoad() async {
    setLevelSize();
    add(_sprite = SpriteComponent(
      sprite: await Sprite.load('taptap_note.png'),
      size: size,
      position: Vector2(0, 0),
      priority: 5,
    ));
    if (holdDuration > 0) {
      add(_noteBar = TapTapNoteBar(
        holdDuration: holdDuration,
        priority: -1,
        anchor: Anchor.bottomCenter,
        position: size / 2,
        size: Vector2(
            size.x / 4,
            holdDuration *
                    ((levelSize.y * hitCircleYPlacementModifier) /
                        SongLevelComponent.INTERVAL_TIMING_MULTIPLIER) -
                (size.y / 2)),
      ));
    }
    double currentTiming = currentTimingOfNote;
    final double currentProgress = currentTiming / timeNoteIsVisible;
    _sprite.position.y = min(currentProgress, 1) * fullNoteTravelDistance;
    _noteBar?.position.y =
        min(currentProgress, 1) * fullNoteTravelDistance + (size.y / 2);
    // Add Effect to move to the end location.
    _sprite.add(MoveEffect.to(Vector2(0, fullNoteTravelDistance),
        LinearEffectController(timeNoteIsVisible - currentTiming)));
    _noteBar?.add(MoveEffect.to(
        Vector2(size.x / 2, fullNoteTravelDistance + (size.y / 2)),
        LinearEffectController(timeNoteIsVisible - currentTiming)));
    await super.onLoad();
  }

  @override
  void update(double dt) {
    // Check if the note should be removed from the scene.
    if (currentTimingOfNote >= timeNoteIsVisible && !isRemovingFromParent) {
      _remove();
    }
    super.update(dt);
  }

  /// Determines if a hit at this exact moment would be considered successful.
  bool isSuccessfulHit() {
    return currentTimingOfNote >= timeUntilNoteCanBeHit &&
        currentTimingOfNote <= timeNoteIsInQueue;
  }

  /// Called if a note is tapped and cleared successfully.
  void hit() {
    // Remove all active effects from sprite only.
    // _sprite.children.removeWhere((c) => c is Effect);
    _sprite.removeWhere((c) => c is Effect);
    if (_noteBar != null) {
      _noteBar!.holding(
        spriteCenterPosition: Vector2(_sprite.x, _sprite.y + (size.y / 2)),
      );
      // Add some transparency to the note sprite, to see the bar behind it.
      _sprite.paint
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 50)
        ..colorFilter =
            ColorFilter.mode(Colors.white.withOpacity(0.8), BlendMode.modulate);
      // set last point update time to the start of the note hit.
      lastPointUpdateTime = gameRef.currentLevel.songTime;
    } else {
      isRemovingFromParent = true;
      // update with a glow.
      _sprite.paint
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30)
        ..colorFilter = ColorFilter.mode(Colors.greenAccent, BlendMode.overlay);
      // remove the note after a short time of displaying.
      add(RemoveEffect(delay: 0.1));
    }
  }

  /// Update score for a held note (since the last time it was update).
  void updateHeldNoteScore(double percentageOfBeatInterval) {
    if (lastPointUpdateTime != null) {
      gameRef.currentLevel.scoreComponent
          .noteHeld(MiniGameType.tapTap, percentageOfBeatInterval);
      // Update last updated score to now.
      lastPointUpdateTime = gameRef.currentLevel.songTime;
    }
  }

  /// Called if a note was being held but was released.
  void released() {
    if (_noteBar != null) {
      _noteBar!.dead();
      // update sprite with a glow and hid it.
      _sprite.paint
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 30)
        ..colorFilter = ColorFilter.mode(Colors.greenAccent, BlendMode.overlay);
      // Hide sprite. (Applying a SizeEffect controller that does nothing just to add a delay to hide the sprite.
      _sprite.add(SizeEffect.to(_sprite.size, LinearEffectController(0.1))
        ..onComplete = () => _sprite.size = Vector2.all(0));
    }
  }

  /// Called if a held note has reach the end of its note bar.
  void endOfNoteBarReached() {
    if (_noteBar != null) {
      // hide note bar completely.
      _noteBar!.size = Vector2.all(0);
      // Apply same other effects as when releasing.
      released();
    }
  }

  /// Called if the note has been missed by the player and is no longer tappable.
  void noLongerTappable() {
    // Apply a grayscale filter over the sprite image. This example is shown in the ColorFilter.matrix documentation.
    _sprite.paint
      ..colorFilter = ColorFilter.matrix(<double>[
        0.2126, 0.7152, 0.0722, 0, 0, //
        0.2126, 0.7152, 0.0722, 0, 0, //
        0.2126, 0.7152, 0.0722, 0, 0, //
        0, 0, 0, 1, 0, //
      ]);
    _noteBar?.dead();
  }

  /// Called if it is time for the note to be removed from view.
  void _remove() {
    isRemovingFromParent = true;
    // remove the note after a short time of displaying.
    if (_noteBar != null) {
      add(RemoveEffect(
          delay: (timeNoteIsVisible /
              SongLevelComponent.INTERVAL_TIMING_MULTIPLIER *
              holdDuration)));
    } else {
      // update with red glow.
      _sprite.paint
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 50)
        ..colorFilter = ColorFilter.mode(Colors.red, BlendMode.overlay);
      add(RemoveEffect(delay: 0.05));
    }
  }
}
