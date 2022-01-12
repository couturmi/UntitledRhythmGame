import 'dart:async' as Async;
import 'dart:collection';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled_rhythm_game/components/games/taptap/taptap_note.dart';
import 'package:untitled_rhythm_game/components/mixins/game_size_aware.dart';
import 'package:untitled_rhythm_game/main.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class TapTapColumn extends PositionComponent
    with Tappable, GameSizeAware, HasGameRef<MyGame> {
  /// Represents the Y placement of the hit circle out of the game size's full Y axis.
  static const double hitCircleYPlacementModifier = 0.85;

  /// Represents how much of the game size's full Y axis should be allowed above
  /// or below a hit circle to consider a note hit successful.
  static const double hitCircleAllowanceModifier = 0.1; // 0.04

  /// Represents the maximum percentage of the Y-axis that the note should travel before removal.
  static const double noteMaxBoundaryModifier = 1.0;

  /// The number of beat intervals it should take a note to reach the hit circle.
  /// TODO 2 = hard, 3 = medium, 4 = easy
  static const int intervalTimingMultiplier = 2;

  /// Column placement in board (from the left).
  final int columnIndex;

  late CircleComponent hitCircle;

  final Queue<TapTapNote> noteQueue = Queue();

  TapTapColumn({required this.columnIndex});

  @override
  Future<void> onLoad() async {
    anchor = Anchor.topLeft;
    size = Vector2(gameSize.x / 3, gameSize.y);

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

  addNote({required int interval, required double beatDelay}) {
    // Create note component.
    final TapTapNote noteComponent = TapTapNote(
      diameter: gameSize.x / 3,
      position: Vector2(0, 0),
      anchor: Anchor.centerLeft,
    );

    // Set delay for when the note should appear.
    Async.Timer(Duration(microseconds: (interval * beatDelay).round()), () {
      noteQueue.addFirst(noteComponent);
      add(noteComponent);
      // Sets the movement in such a way that the note will cross the hit circle exactly on beat.
      double fullNoteTravelDistance = gameSize.y * (noteMaxBoundaryModifier);
      double timeNoteIsVisible =
          timeForNoteToTravel(noteMaxBoundaryModifier, interval);
      double timeNoteIsInQueue = timeForNoteToTravel(
          hitCircleYPlacementModifier + hitCircleAllowanceModifier, interval);
      noteComponent.add(MoveEffect.to(Vector2(0, fullNoteTravelDistance),
          LinearEffectController(microsecondsToSeconds(timeNoteIsVisible))));
      // Set a timer for when the note was definitely missed, and should be removed from hittable notes queue.
      Async.Timer(Duration(microseconds: timeNoteIsInQueue.round()), () {
        if (noteQueue.contains(noteComponent)) {
          noteQueue.remove(noteComponent);
          // Update score with miss.
          gameRef.currentLevel.scoreComponent.resetStreak();
        }
      });
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
    return ((yPercentageTarget) * beatInterval * intervalTimingMultiplier) /
        hitCircleYPlacementModifier;
  }

  @override
  bool onTapDown(TapDownInfo info) {
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
    return true;
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
    position = Vector2((gameSize.x / 3) * columnIndex, 0);
  }
}
