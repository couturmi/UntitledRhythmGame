import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class OsuNoteBar extends ShapeComponent {
  final Vector2 startCircleCenterPosition;
  final Vector2 endCircleCenterPosition;
  final double noteRadius;
  bool showEndReverseArrow;
  bool showStartReverseArrow;

  final Paint _outlinePaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 5;

  OsuNoteBar({
    required this.startCircleCenterPosition,
    required this.endCircleCenterPosition,
    required this.noteRadius,
    required this.showEndReverseArrow,
    required this.showStartReverseArrow,
    super.paint,
    super.priority,
  }) : super(position: startCircleCenterPosition);

  double get xDistance =>
      endCircleCenterPosition.x - startCircleCenterPosition.x;
  double get yDistance =>
      endCircleCenterPosition.y - startCircleCenterPosition.y;
  double get hypotenuse =>
      sqrt(pow(xDistance.abs(), 2) + pow(yDistance.abs(), 2));

  @override
  Future<void> onLoad() async {
    // Find the angle the ending of the arc should be at to point at the starting note.
    // Source: https://stackoverflow.com/questions/1211212/how-to-calculate-an-angle-from-three-points
    Vector2 p1 = startCircleCenterPosition;
    Vector2 p2 = Vector2(hypotenuse.abs(), p1.y);
    Vector2 p3 = endCircleCenterPosition;
    double angleToEndCircle =
        atan2(p3.y - p1.y, p3.x - p1.x) - atan2(p2.y - p1.y, p2.x - p1.x);
    angle = angleToEndCircle;

    await super.onLoad();
  }

  void hideEndReverseArrow() {
    showEndReverseArrow = false;
  }

  void hideStartReverseArrow() {
    showStartReverseArrow = false;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    // make sure outline paint copies the current opacity.
    _outlinePaint.color = _outlinePaint.color.withAlpha(paint.color.alpha);

    // draw semi-circle start fill
    canvas.drawArc(
      Rect.fromLTWH(
        -noteRadius,
        -noteRadius,
        noteRadius * 2,
        noteRadius * 2,
      ),
      pi / 2,
      pi,
      true,
      paint,
    );
    // draw semi-circle start outline
    canvas.drawArc(
      Rect.fromLTWH(
        -noteRadius,
        -noteRadius,
        noteRadius * 2,
        noteRadius * 2,
      ),
      pi / 2,
      pi,
      false,
      _outlinePaint,
    );

    // draw semi-circle end fill
    canvas.drawArc(
      Rect.fromLTWH(
        hypotenuse - noteRadius,
        -noteRadius,
        noteRadius * 2,
        noteRadius * 2,
      ),
      -pi / 2,
      pi,
      true,
      paint,
    );
    // draw semi-circle end outline
    canvas.drawArc(
      Rect.fromLTWH(
        hypotenuse - noteRadius,
        -noteRadius,
        noteRadius * 2,
        noteRadius * 2,
      ),
      -pi / 2,
      pi,
      false,
      _outlinePaint,
    );

    // draw center fill
    canvas.drawRect(
      Rect.fromLTWH(
        -0.15, // -0.15 to cover extra pixel that is not painted
        -noteRadius,
        hypotenuse + 0.3, // +0.3 to cover extra pixel that is not painted
        noteRadius * 2,
      ),
      paint,
    );
    // draw top connecting line
    canvas.drawLine(
      Offset(
        -0.15, // -0.15 to cover extra pixel that is not painted
        -noteRadius,
      ),
      Offset(
        hypotenuse + 0.15, // +0.15 to cover extra pixel that is not painted
        -noteRadius,
      ),
      _outlinePaint,
    );
    // draw bottom connecting line
    canvas.drawLine(
      Offset(
        -0.15, // -0.15 to cover extra pixel that is not painted
        noteRadius,
      ),
      Offset(
        hypotenuse + 0.15, // +0.15 to cover extra pixel that is not painted
        noteRadius,
      ),
      _outlinePaint,
    );

    // Draw start arrow if necessary
    if (showStartReverseArrow) {
      canvas.drawArc(
        Rect.fromLTWH(
          -noteRadius,
          -noteRadius,
          noteRadius * 2,
          noteRadius * 2,
        ),
        0,
        pi * 2,
        true,
        Paint()
          ..color = _outlinePaint.color
              .withOpacity(min(_outlinePaint.color.opacity, 0.6)),
      );
      final tipPath = Path();
      tipPath.moveTo(-(noteRadius / 2), -(noteRadius / 4));
      tipPath.lineTo(0, -(noteRadius / 4));
      tipPath.lineTo(0, -(noteRadius / 2));
      tipPath.lineTo((noteRadius / 2), 0);
      tipPath.lineTo(0, (noteRadius / 2));
      tipPath.lineTo(0, (noteRadius / 4));
      tipPath.lineTo(-(noteRadius / 2), (noteRadius / 4));
      tipPath.close();
      canvas.drawPath(tipPath, paint);
    }

    // Draw end arrow if necessary
    if (showEndReverseArrow) {
      canvas.drawArc(
        Rect.fromLTWH(
          hypotenuse - noteRadius,
          -noteRadius,
          noteRadius * 2,
          noteRadius * 2,
        ),
        0,
        pi * 2,
        true,
        Paint()
          ..color = _outlinePaint.color
              .withOpacity(min(_outlinePaint.color.opacity, 0.6)),
      );
      final tipPath = Path();
      tipPath.moveTo(hypotenuse + (noteRadius / 2), -(noteRadius / 4));
      tipPath.lineTo(hypotenuse, -(noteRadius / 4));
      tipPath.lineTo(hypotenuse, -(noteRadius / 2));
      tipPath.lineTo(hypotenuse - (noteRadius / 2), 0);
      tipPath.lineTo(hypotenuse, (noteRadius / 2));
      tipPath.lineTo(hypotenuse, (noteRadius / 4));
      tipPath.lineTo(hypotenuse + (noteRadius / 2), (noteRadius / 4));
      tipPath.close();
      canvas.drawPath(tipPath, paint);
    }
  }
}
