import 'dart:collection';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/experimental.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/games/minigame_type.dart';
import 'package:untitled_rhythm_game/components/games/osu/osu_note.dart';
import 'package:untitled_rhythm_game/components/mixins/game_size_aware.dart';
import 'package:untitled_rhythm_game/my_game.dart';
import 'package:untitled_rhythm_game/song_level_component.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class OsuNoteArea extends PositionComponent
    with GameSizeAware, HasGameRef<MyGame>, DragCallbacks {
  /// Diameter of a note.
  static const double noteDiameter = 120;

  /// Margin for where the game area should be held. This is so the notes aren't
  /// added too close to the edge.
  final Vector2 gameAreaMargin = Vector2(130.0, 70.0);

  /// Queue for notes that are currently displayed and able to be hit.
  final Queue<OsuNote> noteQueue = Queue();

  /// Queue for notes that are yet to be displayed and are waiting for the exact timing.
  final Queue<OsuNote> upcomingNoteQueue = Queue();

  /// Used to store a note that is currently playing through a drag action.
  OsuNote? _currentDraggableNote;

  /// Determines the priority of the next note to display, so that is is always
  /// visually in front of the note after it.
  int nextNotePriority = 999;

  OsuNoteArea() : super(anchor: Anchor.topLeft);

  Future<void> onLoad() async {
    size = this.gameSize - (gameAreaMargin * 2);
    position = gameAreaMargin;
    super.onLoad();
  }

  @override
  void update(double dt) {
    // Check if any new notes need to be added.
    upcomingNoteQueue.removeWhere((newNote) {
      if (newNote.expectedTimeOfStart <= gameRef.currentLevel.songTime) {
        noteQueue.addLast(newNote);
        add(newNote);
        return true;
      }
      return false;
    });
    // Check if the note was definitely missed, and should be removed from hittable notes queue.
    noteQueue.removeWhere((note) {
      if (note.currentTimingOfNote >= note.timeNoteIsInQueue) {
        note.missed();
        // Update score with miss.
        gameRef.currentLevel.scoreComponent.missed(MiniGameType.osu);
        return true;
      }
      return false;
    });
    super.update(dt);
  }

  void addNote({
    required double duration,
    required int interval,
    required int exactTiming,
    required double xPercentage,
    required double yPercentage,
    required double xPercentageEnd,
    required double yPercentageEnd,
    required String label,
  }) {
    // Create note component.
    final double timeNoteIsInQueue =
        (interval * SongLevelComponent.INTERVAL_TIMING_MULTIPLIER) +
            (interval * OsuNote.timingRingHitAllowanceModifier);
    final noteStartingPosition =
        calculateNotePosition(xPercentage, yPercentage);
    final noteEndingPosition =
        calculateNotePosition(xPercentageEnd, yPercentageEnd);
    final OsuNote noteComponent = OsuNote(
      diameter: noteDiameter,
      position: noteStartingPosition,
      endRelativePosition: (noteEndingPosition - noteStartingPosition),
      anchor: Anchor.center,
      holdDuration: duration,
      timeNoteIsInQueue: microsecondsToSeconds(timeNoteIsInQueue),
      expectedTimeOfStart: microsecondsToSeconds(exactTiming),
      beatInterval: interval,
      label: label,
      priority: nextNotePriority,
    );
    nextNotePriority--;
    upcomingNoteQueue.addLast(noteComponent);
  }

  Vector2 calculateNotePosition(double xPercentage, double yPercentage) {
    return Vector2(size.x * xPercentage, size.y * yPercentage);
  }

  void onGameAreaTapped(TapDownEvent event) {
    // Check if a note collision occurred with any notes in the queue.
    // Note: All notes need to be checked rather than just checking the top note
    // in the queue since the note location is 2-dimensional.
    OsuNote? successfulHitOnNote;
    for (OsuNote note in noteQueue) {
      // location is within range of note
      double noteRadius = noteDiameter / 2;
      if (note.absolutePosition.distanceTo(event.canvasPosition) <=
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
      // If this is a held/draggable note, save a copy now.
      if (successfulHitOnNote.holdDuration > 0) {
        _currentDraggableNote = successfulHitOnNote;
      }
      // Update UI.
      noteQueue.remove(successfulHitOnNote);
      successfulHitOnNote.hit();
      // Update score with hit.
      gameRef.currentLevel.scoreComponent.noteHit(MiniGameType.osu);
    }
    // If a note was not hit.
    else {
      performHighlight(Colors.red);
      // Reset score streak;
      gameRef.currentLevel.scoreComponent.resetStreak();
    }
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {}

  @override
  void onDragEnd(DragEndEvent event) {
    if (_currentDraggableNote != null) {
      _currentDraggableNote = null;
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
    highlight.add(RemoveEffect(delay: 0.1));
    parent?.add(highlight);
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    this.onResize(Vector2(gameSize.y, gameSize.x));
  }
}
