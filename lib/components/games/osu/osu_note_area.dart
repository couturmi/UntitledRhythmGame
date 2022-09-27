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
    with GameSizeAware, HasGameRef<MyGame> {
  /// Diameter of a note.
  static const double noteDiameter = 120;

  /// Represents the number of pixels outside the note to still consider the
  /// draggable note as within range.
  static const double dragRangeAllowanceModifier = 20;

  /// Margin for where the game area should be held. This is so the notes aren't
  /// added too close to the edge.
  final Vector2 gameAreaMargin = Vector2(130.0, 70.0);

  /// Queue for notes that are currently displayed and able to be hit.
  final Queue<OsuNote> noteQueue = Queue();

  /// Queue for notes that are yet to be displayed and are waiting for the exact timing.
  final Queue<OsuNote> upcomingNoteQueue = Queue();

  /// Used to store a note that is currently playing through a drag action.
  OsuNote? _currentDraggableNote;

  /// Represents the last drag event position that occurred to follow [_currentDraggableNote].
  Vector2? lastDragPosition;

  /// Determines the priority of the next note to display, so that is is always
  /// visually in front of the note after it.
  int nextNotePriority = 999;

  OsuNoteArea() : super(anchor: Anchor.topLeft);

  double get heldNoteHitBoxRadius =>
      noteDiameter / 2 + dragRangeAllowanceModifier;

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
    // If note is draggable, award points if within range.
    if (_currentDraggableNote != null) {
      OsuNote note = _currentDraggableNote!;
      // First, check if the [lastDragEvent] is in range of the current draggable note.
      // If the player is dragging (within range of) the note.
      if (lastDragPosition != null &&
          note.currentAbsoluteCenterOfNoteCircle
                  .distanceTo(lastDragPosition!) <=
              heldNoteHitBoxRadius) {
        note.inDraggingRange();
        // Note: The only reason this is added in so many places is to show live progression of the score
        // as the player holds the note. Otherwise, we could easily just calculate it after the player
        // releases, but that's not as COOL.
        note.updateHeldNoteScoreIfInRange();
      }
      // If the player is no longer dragging (within range of) the note.
      else {
        note.updateHeldNoteScoreIfInRange();
        note.leftDraggingRange();
      }

      // If the note bar has run out, clear the note as the held note.
      if (gameRef.currentLevel.songTime >= note.expectedTimeOfFinish) {
        // Notify that end has been reached.
        note.endOfNoteBarReached();
        _currentDraggableNote = null;
        lastDragPosition = null;
      }
    }
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
    required int reversals,
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
      reversals: reversals,
      timeNoteIsInQueue: microsecondsToSeconds(timeNoteIsInQueue),
      expectedTimeOfStart: microsecondsToSeconds(exactTiming),
      beatInterval: microsecondsToSeconds(interval),
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
    // [lastDragPosition] is set to tap event position in case the user never
    // ends up dragging, therefore never triggering an [onGameAreaDragUpdate()].
    lastDragPosition = event.canvasPosition;
  }

  void onGameAreaDragUpdate(DragUpdateEvent event) {
    if (_currentDraggableNote != null) {
      // Update last drag position to current even position.
      lastDragPosition = event.canvasPosition;
      // Check if player is within dragging range of the note.
      if (_currentDraggableNote!.currentAbsoluteCenterOfNoteCircle
              .distanceTo(lastDragPosition!) <=
          heldNoteHitBoxRadius) {
        _currentDraggableNote!.inDraggingRange();
      }
      // If the player is no longer dragging (within range of) the note.
      else {
        _currentDraggableNote!.updateHeldNoteScoreIfInRange();
        _currentDraggableNote!.leftDraggingRange();
      }
    }
  }

  void onGameAreaTapUp(TapUpEvent event) {
    if (_currentDraggableNote != null) {
      _currentDraggableNote!.updateHeldNoteScoreIfInRange();
      _currentDraggableNote!.leftDraggingRange();
    }
  }

  void onGameAreaDragEnd(DragEndEvent event) {
    if (_currentDraggableNote != null) {
      _currentDraggableNote!.updateHeldNoteScoreIfInRange();
      _currentDraggableNote!.leftDraggingRange();
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
