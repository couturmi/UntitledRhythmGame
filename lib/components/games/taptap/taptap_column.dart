import 'dart:collection';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/experimental.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled_rhythm_game/components/games/taptap/taptap_board.dart';
import 'package:untitled_rhythm_game/components/games/taptap/taptap_note.dart';
import 'package:untitled_rhythm_game/components/mixins/game_size_aware.dart';
import 'package:untitled_rhythm_game/my_game.dart';
import 'package:untitled_rhythm_game/song_level_component.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class TapTapColumn extends PositionComponent
    with TapCallbacks, GameSizeAware, HasGameRef<MyGame> {
  /// Represents the Y placement of the hit circle out of the game size's full Y axis.
  static const double hitCircleYPlacementModifier = 0.85;

  /// Represents how much of the game size's full Y axis should be allowed above
  /// or below a hit circle to consider a note hit successful.
  static const double hitCircleAllowanceModifier = 0.08; // 0.04

  /// Represents the maximum percentage of the Y-axis that the note should travel before removal.
  static const double noteMaxBoundaryModifier = 1.0;

  /// Column placement in board (from the left).
  final int columnIndex;

  late CircleComponent hitCircle;

  /// Queue for notes that are currently displayed and able to be hit.
  final Queue<TapTapNote> noteQueue = Queue();

  /// Queue for notes that are yet to be displayed and are waiting for the exact timing.
  final Queue<TapTapNote> upcomingNoteQueue = Queue();

  TapTapColumn({required this.columnIndex});

  @override
  Future<void> onLoad() async {
    anchor = Anchor.topLeft;
    size =
        Vector2(gameSize.x / TapTapBoardComponent.numberOfColumns, gameSize.y);

    final columnBoundaries = RectangleComponent(
      size: size,
      position: Vector2(0, 0),
      anchor: Anchor.topLeft,
      paint: BasicPalette.white.paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    hitCircle = CircleComponent(
      radius: gameSize.x / 6,
      position: Vector2(0, gameSize.y * hitCircleYPlacementModifier),
      anchor: Anchor.centerLeft,
      paint: Paint()..color = Colors.white.withOpacity(0.6),
    );
    add(columnBoundaries);
    add(hitCircle);

    super.onLoad();
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
    // Check if the note was definitely missed, and should be removed from hittable notes queue.
    bool anyNotesMissed = false;
    noteQueue.removeWhere((note) {
      if (note.currentTimingOfNote >= note.timeNoteIsInQueue) {
        anyNotesMissed = true;
        return true;
      }
      return false;
    });
    if (anyNotesMissed) {
      // Update score with miss.
      gameRef.currentLevel.scoreComponent.resetStreak();
    }
    super.update(dt);
  }

  addNote({
    required int exactTiming,
    required int interval,
  }) {
    // Sets the movement in such a way that the note will cross the hit circle exactly on beat.
    double fullNoteTravelDistance = gameSize.y * (noteMaxBoundaryModifier);
    double timeNoteIsVisible =
        timeForNoteToTravel(noteMaxBoundaryModifier, interval);
    double timeNoteIsInQueue = timeForNoteToTravel(
        hitCircleYPlacementModifier + hitCircleAllowanceModifier, interval);

    // Create note component.
    final TapTapNote noteComponent = TapTapNote(
      diameter: gameSize.x / 3,
      position: Vector2(0, 0),
      anchor: Anchor.centerLeft,
      expectedTimeOfStart: microsecondsToSeconds(exactTiming),
      fullNoteTravelDistance: fullNoteTravelDistance,
      timeNoteIsInQueue: microsecondsToSeconds(timeNoteIsInQueue),
      timeNoteIsVisible: microsecondsToSeconds(timeNoteIsVisible),
    );
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
        hitCircleYPlacementModifier;
  }

  @override
  void onTapDown(TapDownEvent _) {
    // Grab the last note in the queue that hasn't passed the hit circle threshold.
    final TapTapNote frontNoteComponent = noteQueue.last;
    // Check if a note collision occurred.
    bool successfulHit = (hitCircle.y - frontNoteComponent.y).abs() <=
        gameSize.y * hitCircleAllowanceModifier;
    // If note was hit.
    if (successfulHit) {
      // Update UI.
      noteQueue.remove(frontNoteComponent);
      frontNoteComponent.hit();
      performHighlight(Colors.lightBlueAccent);
      // Update score with hit.
      gameRef.currentLevel.scoreComponent.tapTapHit();
      HapticFeedback.lightImpact();
    }
    // If note was not hit.
    else {
      // Update UI.
      performHighlight(Colors.red);
      // Reset score streak;
      gameRef.currentLevel.scoreComponent.resetStreak();
    }
  }

  /// Add a temporary highlight to the column that will quickly disappear.
  void performHighlight(Color highlightColor) {
    final highlight = RectangleComponent(
      size: size,
      position: Vector2(0, 0),
      anchor: Anchor.topLeft,
      paint: Paint()..color = highlightColor.withOpacity(0.3),
    );
    highlight.add(RemoveEffect(delay: 0.1));
    add(highlight);
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    this.onResize(gameSize);
    position = Vector2(
        (gameSize.x / TapTapBoardComponent.numberOfColumns) * columnIndex, 0);
  }
}
