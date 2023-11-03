import 'dart:collection';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled_rhythm_game/components/games/minigame_type.dart';
import 'package:untitled_rhythm_game/components/games/taptap/taptap_note.dart';
import 'package:untitled_rhythm_game/components/mixins/level_size_aware.dart';
import 'package:untitled_rhythm_game/my_game.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class TapTapColumn extends PositionComponent
    with TapCallbacks, HasGameRef<MyGame>, LevelSizeAware {
  /// Represents the default value [hitCircleYPlacementModifier].
  static const double hitCircleYPlacementModifierDefault = 0.85;

  /// Represents how much of the game size's full Y axis should be allowed above
  /// or below a hit circle to consider a note hit successful.
  static const double hitCircleAllowanceModifier = 0.08; // 0.04

  /// Represents the maximum percentage of the Y-axis that the note should travel before removal.
  static const double noteMaxBoundaryModifier = 1.0;

  /// Total number of columns that make up this TapTap board.
  final int numberOfColumns;

  /// Represents the Y placement of the hit circle out of the game size's full Y axis.
  late final double hitCircleYPlacementModifier;

  /// Column placement in board (from the left).
  final int columnIndex;

  late CircleComponent hitCircle;

  /// Queue for notes that are currently displayed and able to be hit.
  final Queue<TapTapNote> noteQueue = Queue();

  /// Queue for notes that are yet to be displayed and are waiting for the exact timing.
  final Queue<TapTapNote> upcomingNoteQueue = Queue();

  /// Used to store a note that is currently being held.
  TapTapNote? _currentHeldNote;

  /// Determines the priority of the next note to display, so that is is always
  /// visually in front of the note after it.
  int nextNotePriority = 999;

  TapTapColumn({
    required this.columnIndex,
    required this.numberOfColumns,
  });

  @override
  Future<void> onLoad() async {
    setLevelSize();
    anchor = Anchor.topLeft;
    size = Vector2(levelSize.x / numberOfColumns, levelSize.y);
    position = Vector2((this.levelSize.x / numberOfColumns) * columnIndex, 0);
    hitCircleYPlacementModifier = min(
      // default
      hitCircleYPlacementModifierDefault,
      // percentage if the note is placed directly at the bottom of the screen.
      ((levelSize.y - (levelSize.x / (numberOfColumns * 2))) / levelSize.y) -
          0.02,
    );

    final columnBoundaries = RectangleComponent(
      size: Vector2(size.x, size.y + 100),
      position: Vector2(0, levelSize.y),
      anchor: Anchor.bottomLeft,
      paint: BasicPalette.white.paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    hitCircle = CircleComponent(
      radius: levelSize.x / (numberOfColumns * 2),
      position: Vector2(0, levelSize.y * hitCircleYPlacementModifier),
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
    noteQueue.removeWhere((note) {
      if (note.currentTimingOfNote >= note.timeNoteIsInQueue) {
        note.noLongerTappable();
        // Update score with miss.
        gameRef.currentLevel.scoreComponent.missed(MiniGameType.tapTap,
            durationOfBeatInterval: note.holdDuration);
        return true;
      }
      return false;
    });
    // If a note is being held, add points for it.
    if (_currentHeldNote != null) {
      TapTapNote note = _currentHeldNote!;
      // Check if the note should still be able to be held (The note bar hasn't run out).
      // Note: The only reason this is added in so many places is to show live progression of the score
      // as the player holds the note. Otherwise, we could easily just calculate it after the player
      // releases, but that's not as COOL.
      if (gameRef.currentLevel.songTime < note.expectedTimeOfFinish) {
        note.updateHeldNoteScore(
          (gameRef.currentLevel.songTime - note.lastPointUpdateTime!) /
              note.interval,
        );
      }
      // Otherwise, clear the note as the held note.
      else {
        // Update score with remaining expected points.
        note.updateHeldNoteScore(
          (note.expectedTimeOfFinish - note.lastPointUpdateTime!) /
              note.interval,
        );
        // Notify that end has been reached.
        note.endOfNoteBarReached();
        _currentHeldNote = null;
      }
    }
    super.update(dt);
  }

  addNote({
    required double duration,
    required int exactTiming,
    required int interval,
  }) {
    // Create note component.
    final TapTapNote noteComponent = TapTapNote(
      diameter: levelSize.x / numberOfColumns,
      position: Vector2(0, 0),
      anchor: Anchor.centerLeft,
      holdDuration: duration,
      interval: microsecondsToSeconds(interval),
      expectedTimeOfStart: microsecondsToSeconds(exactTiming),
      priority: nextNotePriority,
      hitCircleYPlacementModifier: hitCircleYPlacementModifier,
    );
    nextNotePriority--;
    upcomingNoteQueue.addFirst(noteComponent);
  }

  @override
  void onTapDown(TapDownEvent _) {
    // Grab the last note in the queue that hasn't passed the hit circle threshold.
    final TapTapNote? frontNoteComponent = noteQueue.lastOrNull;
    // Check if a note collision occurred.
    bool successfulHit = frontNoteComponent?.isSuccessfulHit() ?? false;
    // If note was hit.
    if (successfulHit) {
      // If this is a held note, save a copy now.
      if (frontNoteComponent!.holdDuration > 0) {
        _currentHeldNote = frontNoteComponent;
      }
      noteQueue.remove(frontNoteComponent);
      // Update score with hit.
      gameRef.currentLevel.scoreComponent.noteHit(MiniGameType.tapTap,
          durationOfBeatInterval: frontNoteComponent.holdDuration);
      // Update UI.
      frontNoteComponent.hit();
      performHighlight(Colors.lightBlueAccent);
      HapticFeedback.mediumImpact();
    }
    // If note was not hit.
    else {
      // Update UI.
      performHighlight(Colors.red);
      // Reset score streak;
      gameRef.currentLevel.scoreComponent.resetStreak();
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    if (_currentHeldNote != null) {
      // Update note held score to this moment.
      _currentHeldNote!.updateHeldNoteScore(
        (gameRef.currentLevel.songTime -
                _currentHeldNote!.lastPointUpdateTime!) /
            _currentHeldNote!.interval,
      );
      _currentHeldNote!.released();
      _currentHeldNote = null;
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
}
