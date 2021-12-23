import 'dart:async' as Async;
import 'dart:collection';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/games/taptap/taptap_note.dart';
import 'package:untitled_rhythm_game/components/mixins/knows_game_size.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class TapTapColumn extends PositionComponent with Tappable, KnowsGameSize {
  /// Represents the Y placement of the hit circle out of the game size's full Y axis.
  static const hitCircleYPlacementModifier = 0.85;

  /// Represents how much of the game size's full Y axis should be allowed above
  /// or below a hit circle to consider a note hit successful.
  static const hitCircleAllowanceModifier = 0.04;

  /// Represents the location that the note should continue moving to
  /// past the [hitCircleYPlacementModifier].
  /// The full range of movement would then be:
  ///   0 to ([hitCircleYPlacementModifier] + [noteEndPlacementModifier])
  static const noteEndPlacementModifier = 0.25;

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
      paint: Paint()..color = Colors.white.withOpacity(0.5),
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
      // double fullNoteTravelDistance =
      //     gameSize.y * (hitCircleYPlacementModifier + noteEndPlacementModifier);
      double timeNoteIsVisible = (interval * 2) / hitCircleYPlacementModifier;
      double timeNoteIsInQueue = (interval * 2) +
          ((interval * 2 * hitCircleAllowanceModifier) /
              hitCircleYPlacementModifier);
      noteComponent.add(MoveEffect.to(Vector2(0, gameSize.y),
          LinearEffectController(microsecondsToSeconds(timeNoteIsVisible))));
      // Set a timer for when the note was definitely missed, and should be removed from hittable notes queue.
      Async.Timer(Duration(microseconds: timeNoteIsInQueue.round()), () {
        noteQueue.remove(noteComponent);
      });
      // Set a timer for when the note should be remove from the scene.
      Async.Timer(Duration(microseconds: timeNoteIsVisible.round()), () {
        noteComponent.missed();
      });
    });
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
      noteQueue.remove(frontNoteComponent);
      frontNoteComponent.hit();
      performHighlight(Colors.lightBlueAccent);
    }
    // If note was not hit.
    else {
      performHighlight(Colors.red);
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
  void render(Canvas canvas) {
    super.render(canvas);
    // This creates a physical boundary that can be tapped.
    canvas.drawRect(size.toRect(), Paint()..color = Colors.transparent);
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    this.onResize(gameSize);
    position = Vector2((gameSize.x / 3) * columnIndex, 0);
  }
}
