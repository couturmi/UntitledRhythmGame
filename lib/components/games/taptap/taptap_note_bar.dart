import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/mixins/game_size_aware.dart';

class TapTapNoteBar extends PositionComponent with GameSizeAware {
  /// Duration (in percentage of an interval) that this note should be held after being tapped.
  /// A note with no holding will have a [holdDuration] of 0;
  final double holdDuration;

  /// Exact position that the note is being held at. Null if the note is not being held.
  Vector2? _isBeingHeldAt;

  late final RectangleComponent _barFill;
  late final RectangleComponent _barBorder;

  TapTapNoteBar({
    super.position,
    super.anchor,
    super.priority,
    super.size,
    required this.holdDuration,
  });

  Future<void> onLoad() async {
    if (holdDuration > 0) {
      add(_barFill = RectangleComponent(
        priority: 1,
        paint: Paint()..color = Colors.blue.shade700,
        anchor: Anchor.bottomRight,
        position: size,
        size: size,
      ));
      add(_barBorder = RectangleComponent(
        priority: 0,
        paint: Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
        anchor: Anchor.bottomRight,
        position: size,
        size: size,
      ));
    }
    await super.onLoad();
  }

  void holding({required Vector2 spriteCenterPosition}) {
    _isBeingHeldAt = spriteCenterPosition;
    _barFill.paint.color = Colors.lightBlue.shade300;
    _barBorder.paint.color = Colors.lightBlue.shade100;
  }

  void dead() {
    _isBeingHeldAt = null;
    _barFill.paint.color = Colors.grey.shade700;
    _barBorder.paint.color = Colors.grey;
  }

  @override
  void render(Canvas canvas) {
    // If this note is being held, clip the view of the back end of the note from the canvas.
    // THIS SOME HACKY SHIT!
    if (_isBeingHeldAt != null) {
      final rect = Rect.fromLTWH(
        -size.x,
        -position.y + size.y,
        size.x * 3,
        _isBeingHeldAt!.y, // clip in the middle of the note sprite.
      );
      canvas.drawRect(rect, Paint()..color = Colors.transparent);
      canvas.clipRect(rect);
      canvas.save();
      canvas.restore();
    }
    super.render(canvas);
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    this.onResize(canvasSize);
  }
}
