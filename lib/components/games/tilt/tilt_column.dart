import 'dart:collection';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/games/minigame_type.dart';
import 'package:untitled_rhythm_game/components/games/tilt/tilt_game_component.dart';
import 'package:untitled_rhythm_game/components/games/tilt/tilt_note.dart';
import 'package:untitled_rhythm_game/components/mixins/game_size_aware.dart';
import 'package:untitled_rhythm_game/my_game.dart';
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

  /// Queue for notes that are currently displayed and able to be hit.
  final Queue<TiltNote> noteQueue = Queue();

  /// Queue for notes that are yet to be displayed and are waiting for the exact timing.
  final Queue<TiltNote> upcomingNoteQueue = Queue();

  /// Determines the priority of the next note to display, so that is is always
  /// visually in front of the note after it.
  int nextNotePriority = 999;

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

  addNote({
    required int exactTiming,
    required int interval,
  }) {
    // Sets the timing in such a way that the note will cross the hit circle exactly on beat.
    double fullNoteTravelDistance = gameSize.y * (noteMaxBoundaryModifier);
    double timeNoteIsVisible =
        timeForNoteToTravel(noteMaxBoundaryModifier, interval);
    // Create note component.
    final TiltNote noteComponent = TiltNote(
      columnIndex: columnIndex,
      diameter: size.x * (3 / 5),
      position: Vector2(size.x / 2, 0),
      anchor: Anchor.center,
      expectedTimeOfStart: microsecondsToSeconds(exactTiming),
      fullNoteTravelDistance: fullNoteTravelDistance,
      timeNoteIsVisible: microsecondsToSeconds(timeNoteIsVisible),
      priority: nextNotePriority,
    );
    nextNotePriority--;
    upcomingNoteQueue.addFirst(noteComponent);
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
    // Check if any new notes need to be added.
    upcomingNoteQueue.removeWhere((newNote) {
      if (newNote.expectedTimeOfStart <= gameRef.currentLevel.songTime) {
        noteQueue.addFirst(newNote);
        add(newNote);
        return true;
      }
      return false;
    });
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
        gameRef.currentLevel.scoreComponent.missed(MiniGameType.tilt);
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
          gameRef.currentLevel.scoreComponent.noteHit(MiniGameType.tilt);
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
    highlight.add(RemoveEffect(delay: 0.1));
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    this.onResize(gameSize);
    position = Vector2(
        (gameSize.x / TiltGameComponent.numberOfColumns) * columnIndex, 0);
  }
}
