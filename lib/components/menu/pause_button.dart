import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/off_beat_game.dart';

abstract class SimpleButton extends PositionComponent with TapCallbacks {
  static const double defaultSize = 40;

  SimpleButton(this._iconPath, {super.position, super.anchor})
      : super(size: Vector2.all(defaultSize));

  final Paint _borderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0x66ffffff);
  final Paint _iconPaint = Paint()
    ..style = PaintingStyle.stroke
    ..color = const Color(0xffaaaaaa)
    ..strokeWidth = 7;
  final Path _iconPath;

  void action();

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(8)),
      _borderPaint,
    );
    canvas.drawPath(_iconPath, _iconPaint);
  }

  @override
  void onTapDown(TapDownEvent event) {
    _iconPaint.color = const Color(0xffffffff);
  }

  @override
  void onTapUp(TapUpEvent event) {
    _iconPaint.color = const Color(0xffaaaaaa);
    action();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _iconPaint.color = const Color(0xffaaaaaa);
  }
}

class PauseButton extends SimpleButton with HasGameRef<OffBeatGame> {
  /// True if the pause button should be entirely hidden from the screen.
  bool _hidden = false;

  /// Timer that prevents the pause button from being spammed.
  Timer? _lastTappedTimer;

  PauseButton({super.position, super.anchor})
      : super(
          Path()
            ..moveTo(14, 10)
            ..lineTo(14, 30)
            ..moveTo(26, 10)
            ..lineTo(26, 30),
        );
  @override
  void action() {
    if (!_hidden && _lastTappedTimer == null) {
      FlameAudio.play('effects/button_click.mp3');
      gameRef.router.pushNamed(GameRoutes.pause.name);
      _lastTappedTimer = Timer(
        1,
        repeat: false,
        onTick: () {
          _lastTappedTimer = null;
        },
      );
    }
  }

  void hide() {
    _hidden = true;
  }

  void show() {
    _hidden = false;
  }

  @override
  void render(Canvas canvas) {
    if (!_hidden) {
      super.render(canvas);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (_lastTappedTimer == null) {
      super.onTapDown(event);
    }
  }

  @override
  void update(double dt) {
    _lastTappedTimer?.update(dt);
    super.update(dt);
  }
}
