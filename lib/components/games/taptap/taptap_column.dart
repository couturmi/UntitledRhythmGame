import 'dart:async' as Async;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/input.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/games/taptap/taptap_note.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class TapTapColumn extends PositionComponent with Tappable {
  /// Column index (from the left).
  final int columnIndex;

  Vector2 gameSize = Vector2(0, 0);

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
    final hitCircle = CircleComponent(
      radius: gameSize.x / 6,
      position: Vector2(0, gameSize.y * 0.85),
      anchor: Anchor.centerLeft,
      paint: Paint()..color = Colors.white.withOpacity(0.5),
    );
    add(columnBoundaries);
    add(hitCircle);

    super.onLoad();
  }

  addNote({required int interval, required double beatDelay}) {
    // Create note component.
    final noteComponent = TapTapNote(
      diameter: gameSize.x / 3,
      position: Vector2(0, 0),
      anchor: Anchor.centerLeft,
    );
    // Set delay for when the note should appear.
    Async.Timer(Duration(microseconds: (interval * beatDelay).round()), () {
      add(noteComponent);
      noteComponent.add(MoveEffect.to(Vector2(0, gameSize.y * 0.85),
          LinearEffectController(microsecondsToSeconds(interval * 2))));
      Async.Timer(Duration(microseconds: interval * 2), () {
        noteComponent.pop();
      });
    });
  }

  @override
  bool onTapDown(TapDownInfo info) {
    // Check if a note collision occurred.
    bool successfulHit = true;
    // If note was hit.
    if (successfulHit) {
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
      paint: Paint()..color = highlightColor.withOpacity(0.4),
    );
    add(highlight);
    Async.Timer(Duration(milliseconds: 100), () {
      remove(highlight);
    });
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // This creates a physical component that can be tapped.
    canvas.drawRect(size.toRect(), Paint()..color = Colors.transparent);
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    this.gameSize = gameSize;
    position = Vector2((gameSize.x / 3) * columnIndex, 0);
    // position = Vector2((gameSize.x / 3) * columnIndex, gameSize.y / 2);
    // position = Vector2(0, gameSize.y / 2);
  }
}
