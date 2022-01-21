import 'dart:collection';
import 'dart:async' as Async;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/games/tilt/tilt_game_component.dart';
import 'package:untitled_rhythm_game/components/games/tilt/tilt_note.dart';
import 'package:untitled_rhythm_game/components/mixins/game_size_aware.dart';
import 'package:untitled_rhythm_game/main.dart';
import 'package:untitled_rhythm_game/song_level_component.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class TiltColumn extends PositionComponent
    with GameSizeAware, HasGameRef<MyGame> {
  /// Represents the Y placement of the hit circle out of the game size's full Y axis.
  static const double hitCircleYPlacementModifier = 2 / 3;

  /// Represents how much of the game size's full Y axis should be allowed
  /// below a hit circle to consider a note hit successful.
  static const double hitCircleAllowanceModifier = 0.08; // 0.04

  /// Represents the maximum percentage of the Y-axis that the note should travel before removal.
  static const double noteMaxBoundaryModifier = 5 / 6;

  /// Column placement in board (from the left).
  final int columnIndex;

  final Function isPendulumAtThisColumn;

  final Queue<TiltNote> noteQueue = Queue();

  TiltColumn(
      {required this.columnIndex,
      required this.isPendulumAtThisColumn,
      int? priority})
      : super(priority: priority);

  @override
  Future<void> onLoad() async {
    anchor = Anchor.topLeft;
    size = Vector2(gameSize.x / TiltGameComponent.numberOfColumns, gameSize.y);

    final columnBoundaries = RectangleComponent(
      size: size,
      position: Vector2(0, 0),
      anchor: Anchor.topLeft,
      paint: BasicPalette.white.paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    add(columnBoundaries);
    super.onLoad();
  }

  addNote({required int interval, required double beatDelay}) {
    // Create note component.
    final TiltNote noteComponent = TiltNote(
      diameter: size.x * (3 / 5),
      position: Vector2(size.x / 2, 0),
      anchor: Anchor.center,
    );
    // Set delay for when the note should appear.
    Async.Timer(Duration(microseconds: (interval * beatDelay).round()), () {
      noteQueue.addFirst(noteComponent);
      add(noteComponent);
      // Sets the movement in such a way that the note will cross the hit circle exactly on beat.
      double fullNoteTravelDistance = gameSize.y * (noteMaxBoundaryModifier);
      double timeNoteIsVisible =
          timeForNoteToTravel(noteMaxBoundaryModifier, interval);
      noteComponent.add(MoveEffect.to(
          Vector2(size.x / 2, fullNoteTravelDistance),
          LinearEffectController(microsecondsToSeconds(timeNoteIsVisible))));
      // Set a timer for when the note should be remove from the scene.
      Async.Timer(Duration(microseconds: timeNoteIsVisible.round()), () {
        noteComponent.missed();
      });
    });
  }

  /// Calculates the time it should take for a note to travel [yPercentageTarget] percent of the Y-Axis.
  ///
  /// [yPercentageTarget] : percentage of the Y-axis size that the note will have travelled.
  /// [beatInterval] : time it takes for a single beat to complete, in microseconds.
  double timeForNoteToTravel(double yPercentageTarget, int beatInterval) {
    return ((yPercentageTarget) *
            beatInterval *
            SongLevelComponent.INTERVAL_TIMING_MULTIPLIER) /
        (hitCircleYPlacementModifier - hitCircleAllowanceModifier);
  }

  @override
  void update(double dt) {
    // Every update, check if any notes were hit.
    if (noteQueue.isNotEmpty) {
      // Grab the last note in the queue that hasn't passed the hit circle threshold.
      final TiltNote frontNoteComponent = noteQueue.last;

      // Check if the note has passed the hit range of the pendulum yet.
      bool noteIsPassedPendulumArea = frontNoteComponent.y >
          gameSize.y *
              (hitCircleYPlacementModifier + hitCircleAllowanceModifier);
      if (noteIsPassedPendulumArea) {
        noteQueue.remove(frontNoteComponent);
        // Update score with miss.
        gameRef.currentLevel.scoreComponent.resetStreak();
      }

      // Check if the pendulum is at this column.
      if (isPendulumAtThisColumn()) {
        bool noteHasReachedPendulumRange = frontNoteComponent.y >=
            gameSize.y *
                (hitCircleYPlacementModifier - hitCircleAllowanceModifier);
        // If note was hit.
        if (noteHasReachedPendulumRange) {
          // Update UI.
          noteQueue.remove(frontNoteComponent);
          frontNoteComponent.hit(columnIndex);
          performHighlight(Colors.lightBlueAccent);
          // Update score with hit.
          gameRef.currentLevel.scoreComponent.tiltHit();
        }
      }
    }
    super.update(dt);
  }

  /// Add a temporary highlight to the column that will quickly disappear.
  void performHighlight(Color highlightColor) {
    final highlight = RectangleComponent(
      size: size,
      position: Vector2(0, 0),
      anchor: Anchor.topLeft,
      paint: Paint()..color = highlightColor.withOpacity(0.3),
    );
    add(highlight);
    Async.Timer(Duration(milliseconds: 100), () {
      remove(highlight);
    });
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    this.onResize(gameSize);
    position = Vector2(
        (gameSize.x / TiltGameComponent.numberOfColumns) * columnIndex, 0);
  }
}
