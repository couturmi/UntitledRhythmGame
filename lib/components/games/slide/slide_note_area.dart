import 'dart:collection';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/games/slide/bucket_component.dart';
import 'dart:async' as Async;
import 'package:untitled_rhythm_game/components/games/slide/slide_note.dart';
import 'package:untitled_rhythm_game/components/mixins/game_size_aware.dart';
import 'package:untitled_rhythm_game/main.dart';
import 'package:untitled_rhythm_game/song_level_component.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class SlideNoteArea extends PositionComponent
    with GameSizeAware, HasGameRef<MyGame> {
  /// Represents how much of the game size's full Y axis should be allowed
  /// below a hit circle to consider a note hit successful.
  static const double hitCircleAllowanceModifier = 0.08; // 0.04

  /// Represents the maximum percentage of the Y-axis that the note should travel before removal.
  static const double noteMaxBoundaryModifier = 1.0;

  /// Diameter of a note.
  static const double noteDiameter = 120;

  /// Current queue of live/active notes.
  final Queue<SlideNote> noteQueue = Queue();

  final Function getBucketXPosition;

  SlideNoteArea({required this.getBucketXPosition})
      : super(anchor: Anchor.topLeft);

  Future<void> onLoad() async {
    double horizontalMargin = BucketComponent.bucketWidth / 2;
    size = this.gameSize - (Vector2(horizontalMargin, 0) * 2);
    position = Vector2(horizontalMargin, 0);
    super.onLoad();
  }

  void addNote(
      {required int interval,
      required double beatDelay,
      required double xPercentage}) {
    // Create note component.
    final SlideNote noteComponent = SlideNote(
      diameter: noteDiameter,
      position: calculateNotePosition(xPercentage),
      anchor: Anchor.bottomCenter,
    );
    // Set delay for when the note should appear.
    Async.Timer(Duration(microseconds: (interval * beatDelay).round()),
        () async {
      noteQueue.addFirst(noteComponent);
      await add(noteComponent);
      // Sets the movement in such a way that the note will cross the hit circle exactly on beat.
      double fullNoteTravelDistance = gameSize.y * (noteMaxBoundaryModifier);
      double timeNoteIsVisible =
          timeForNoteToTravel(noteMaxBoundaryModifier, interval);
      noteComponent.add(MoveEffect.to(
          Vector2(noteComponent.position.x, fullNoteTravelDistance),
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
        BucketComponent.hitCircleYPlacementModifier;
  }

  Vector2 calculateNotePosition(double xPercentage) {
    return Vector2(size.x * xPercentage, 0);
  }

  @override
  void update(double dt) {
    // Every update, check if any notes were hit.
    if (noteQueue.isNotEmpty) {
      // Grab the last note in the queue that hasn't passed the hit circle threshold.
      final SlideNote frontNoteComponent = noteQueue.last;

      // Check if the note has passed the hit range of the bucket yet.
      bool noteIsPassedBucketArea = frontNoteComponent.y >
          gameSize.y *
              (BucketComponent.hitCircleYPlacementModifier +
                  hitCircleAllowanceModifier);
      if (noteIsPassedBucketArea) {
        noteQueue.remove(frontNoteComponent);
        // Update score with miss.
        gameRef.currentLevel.scoreComponent.resetStreak();
      } else {
        // Check if the note is in the bucket.
        bool noteHasReachedYBucketRange = frontNoteComponent.y >=
            gameSize.y *
                (BucketComponent.hitCircleYPlacementModifier -
                    hitCircleAllowanceModifier);
        double bucketXPosition = getBucketXPosition() - position.x;
        bool noteIsInXBucketRange =
            (frontNoteComponent.x - bucketXPosition).abs() <=
                BucketComponent.bucketWidth / 2;
        if (noteHasReachedYBucketRange) {
          print((frontNoteComponent.x - bucketXPosition).abs());
        }
        // If note was hit.
        if (noteHasReachedYBucketRange && noteIsInXBucketRange) {
          // Update UI.
          noteQueue.remove(frontNoteComponent);
          frontNoteComponent.hit();
          performHighlight(Colors.lightBlueAccent);
          // Update score with hit.
          gameRef.currentLevel.scoreComponent.slideHit();
        }
      }
    }
    super.update(dt);
  }

  /// Add a temporary highlight to the column that will quickly disappear.
  void performHighlight(Color highlightColor) {
    final highlight = RectangleComponent(
      size: gameSize * 7,
      position: Vector2(0, 0),
      anchor: Anchor.topLeft,
      paint: Paint()..color = highlightColor.withOpacity(0.3),
    );
    parent?.add(highlight);
    Async.Timer(Duration(milliseconds: 100), () {
      parent?.remove(highlight);
    });
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    this.onResize(Vector2(gameSize.y, gameSize.x));
  }
}
