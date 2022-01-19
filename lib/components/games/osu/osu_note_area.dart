import 'dart:collection';

import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'dart:async' as Async;
import 'package:untitled_rhythm_game/components/games/osu/osu_note.dart';
import 'package:untitled_rhythm_game/components/mixins/game_size_aware.dart';
import 'package:untitled_rhythm_game/main.dart';
import 'package:untitled_rhythm_game/song_level_component.dart';

class OsuNoteArea extends PositionComponent
    with GameSizeAware, HasGameRef<MyGame> {
  /// Diameter of a note.
  static const double noteDiameter = 120;

  /// Margin for where the game area should be held. This is so the notes aren't
  /// added too close to the edge.
  final Vector2 gameAreaMargin = Vector2(120.0, 60.0);

  /// Current queue of live/active notes.
  final Queue<OsuNote> noteQueue = Queue();

  OsuNoteArea() : super(anchor: Anchor.topLeft);

  Future<void> onLoad() async {
    size = this.gameSize - (gameAreaMargin * 2);
    position = gameAreaMargin;
    super.onLoad();
  }

  void addNote(
      {required int interval,
      required double beatDelay,
      required double xPercentage,
      required double yPercentage}) {
    // Create note component.
    final OsuNote noteComponent = OsuNote(
      diameter: noteDiameter,
      position: calculateNotePosition(xPercentage, yPercentage),
      anchor: Anchor.center,
    );
    // Set delay for when the note should appear.
    Async.Timer(Duration(microseconds: (interval * beatDelay).round()),
        () async {
      noteQueue.addLast(noteComponent);
      await add(noteComponent);
      noteComponent.startTimingEffect(interval);

      // Set a timer for when the note was definitely missed, and should be removed.
      final double timeNoteIsInQueue =
          (interval * SongLevelComponent.INTERVAL_TIMING_MULTIPLIER) +
              (interval * OsuNote.timingRingHitAllowanceModifier);
      Async.Timer(Duration(microseconds: timeNoteIsInQueue.round()), () {
        if (noteQueue.contains(noteComponent)) {
          noteQueue.remove(noteComponent);
          noteComponent.missed();
          // Update score with miss.
          gameRef.currentLevel.scoreComponent.resetStreak();
        }
      });
    });
  }

  Vector2 calculateNotePosition(double xPercentage, double yPercentage) {
    return Vector2(size.x * xPercentage, size.y * yPercentage);
  }

  void onGameAreaTapped(TapDownInfo info) {
    // Check if a note collision occurred with any notes in the queue.
    // Note: All notes need to be checked rather than just checking the top note
    // in the queue since the note location is 2-dimensional.
    OsuNote? successfulHitOnNote;
    for (OsuNote note in noteQueue) {
      // location is within range of note
      double noteRadius = noteDiameter / 2;
      if (note.absolutePosition.distanceTo(info.eventPosition.game) <=
          noteRadius) {
        // if the note timing is correct
        if (note.isHitTimingSuccessful()) {
          successfulHitOnNote = note;
          break;
        }
      }
    }
    // If a note was hit.
    if (successfulHitOnNote != null) {
      // Update UI.
      noteQueue.remove(successfulHitOnNote);
      successfulHitOnNote.hit();
      // Update score with hit.
      gameRef.currentLevel.scoreComponent.osuHit();
    }
    // If a note was not hit.
    else {
      performHighlight(Colors.red);
      // Reset score streak;
      gameRef.currentLevel.scoreComponent.resetStreak();
    }
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
