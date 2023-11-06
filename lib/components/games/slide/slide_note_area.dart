import 'dart:collection';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/games/minigame_type.dart';
import 'package:untitled_rhythm_game/components/games/slide/bucket_component.dart';
import 'package:untitled_rhythm_game/components/games/slide/slide_note.dart';
import 'package:untitled_rhythm_game/components/mixins/level_size_aware.dart';
import 'package:untitled_rhythm_game/my_game.dart';
import 'package:untitled_rhythm_game/components/level/song_level_component.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class SlideNoteArea extends PositionComponent
    with HasGameRef<MyGame>, LevelSizeAware {
  /// Represents how much of the game size's full Y axis should be allowed
  /// below a hit circle to consider a note hit successful.
  static const double hitCircleAllowanceModifier = 0.08; // 0.04

  /// Represents the maximum percentage of the Y-axis that the note should travel before removal.
  static const double noteMaxBoundaryModifier = 1.0;

  /// Diameter of a note.
  static const double noteDiameter = 120;

  /// Queue for notes that are currently displayed and able to be hit.
  final Queue<SlideNote> noteQueue = Queue();

  /// Queue for notes that are yet to be displayed and are waiting for the exact timing.
  final Queue<SlideNote> upcomingNoteQueue = Queue();

  /// Determines the priority of the next note to display, so that is is always
  /// visually in front of the note after it.
  int nextNotePriority = 999;

  final Function getBucketXPosition;

  SlideNoteArea({required this.getBucketXPosition, super.priority})
      : super(anchor: Anchor.topLeft);

  Future<void> onLoad() async {
    setLevelSize();
    double horizontalMargin = BucketComponent.bucketWidth / 2;
    size = this.levelSize - (Vector2(horizontalMargin, 0) * 2);
    position = Vector2(horizontalMargin, 0);
    super.onLoad();
  }

  void addNote(
      {required int exactTiming,
      required int interval,
      required double xPercentage}) {
    // Sets the timing in such a way that the note will cross the hit area exactly on beat.
    double fullNoteTravelDistance = levelSize.y * (noteMaxBoundaryModifier);
    double timeNoteIsVisible =
        timeForNoteToTravel(noteMaxBoundaryModifier, interval);
    // Create note component.
    final SlideNote noteComponent = SlideNote(
      diameter: noteDiameter,
      position: calculateNotePosition(xPercentage),
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
        (1 - BucketComponent.hitCircleYPlacementModifier);
  }

  Vector2 calculateNotePosition(double xPercentage) {
    return Vector2(size.x * xPercentage, levelSize.y);
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
      final SlideNote frontNoteComponent = noteQueue.last;

      // Check if the note has passed the hit range of the bucket yet.
      bool noteIsPassedBucketArea = frontNoteComponent.y <
          levelSize.y *
              (BucketComponent.hitCircleYPlacementModifier -
                  hitCircleAllowanceModifier);
      if (noteIsPassedBucketArea) {
        noteQueue.remove(frontNoteComponent);
        // Update score with miss.
        gameRef.currentLevel.scoreComponent.missed(MiniGameType.slide);
      } else {
        // Check if the note is in the bucket.
        bool noteHasReachedYBucketRange = frontNoteComponent.y <=
            levelSize.y *
                (BucketComponent.hitCircleYPlacementModifier +
                    hitCircleAllowanceModifier);
        double bucketXPosition = getBucketXPosition() - position.x;
        bool noteIsInXBucketRange =
            (frontNoteComponent.x - bucketXPosition).abs() <=
                BucketComponent.bucketWidth / 2;
        // If note was hit.
        if (noteHasReachedYBucketRange && noteIsInXBucketRange) {
          // Update UI.
          noteQueue.remove(frontNoteComponent);
          frontNoteComponent.hit();
          performHighlight(Colors.lightBlueAccent);
          // Update score with hit.
          gameRef.currentLevel.scoreComponent.noteHit(MiniGameType.slide);
        }
      }
    }
    super.update(dt);
  }

  /// Add a temporary highlight to the column that will quickly disappear.
  void performHighlight(Color highlightColor) {
    final highlight = RectangleComponent(
      size: levelSize * 7,
      position: Vector2(0, 0),
      anchor: Anchor.topLeft,
      paint: Paint()..color = highlightColor.withOpacity(0.2),
    );
    parent?.add(highlight);
    highlight.add(RemoveEffect(delay: 0.1));
  }
}
