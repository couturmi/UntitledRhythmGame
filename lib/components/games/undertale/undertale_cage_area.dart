import 'dart:collection';
import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/games/undertale/undertale_gunner.dart';
import 'package:untitled_rhythm_game/components/games/undertale/undertale_joystick.dart';
import 'package:untitled_rhythm_game/components/games/undertale/undertale_player.dart';
import 'package:untitled_rhythm_game/components/mixins/level_size_aware.dart';
import 'package:untitled_rhythm_game/off_beat_game.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class UndertaleCageArea extends PositionComponent
    with HasGameRef<OffBeatGame>, LevelSizeAware {
  /// Margin for where the game play area should be held. All obstacles will be
  /// shot within this area.
  final Vector2 _gameAreaMargin = Vector2.all(20);

  /// Additional margin within the cage area that the users cannot pass.
  final Vector2 _playerAreaMargin = Vector2.all(45);

  /// Queue for obstacles that are yet to be displayed and are waiting for the exact timing.
  final Queue<UndertaleGunner> upcomingGunnerQueue = Queue();

  final UndertaleJoystick joystick;
  late final UndertalePlayer _playerComponent;

  UndertaleCageArea({
    super.anchor,
    super.position,
    required this.joystick,
  });

  /// Actual size of the area the player can move around in.
  Vector2 get playAreaSize => size - (_playerAreaMargin * 2);

  Future<void> onLoad() async {
    setLevelSize();
    size = Vector2.all(levelSize.x) - (_gameAreaMargin * 2);
    // Add cage boundaries.
    add(RectangleComponent(
      priority: 1,
      size: size,
      paint: BasicPalette.white.paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    ));
    add(RectangleComponent(
      priority: -1,
      size: size,
      paint: Paint()..color = Colors.black.withOpacity(0.2),
    ));

    // Add player sprite
    add(_playerComponent = UndertalePlayer(
      size: Vector2.all(size.x * 0.1),
      anchor: Anchor.center,
      position: size / 2,
    ));
    super.onLoad();
  }

  @override
  void update(double dt) {
    // Check if any new gunners need to be added.
    upcomingGunnerQueue.removeWhere((newNote) {
      if (newNote.expectedTimeOfStart <= gameRef.currentLevel.songTime) {
        add(newNote);
        return true;
      }
      return false;
    });
    // Updates the player location based on where the joystick is pointing.
    double? direction = joystick.getCurrentDirection();
    if (direction != null) {
      final Vector2 delta = Vector2(cos(direction), sin(direction));
      final double deltaMultiplier = joystick.intensity * dt * 180;
      Vector2 newPosition =
          _playerComponent.position + (delta * deltaMultiplier);

      if (newPosition.x < _playerAreaMargin.x ||
          newPosition.x > size.x - _playerAreaMargin.x) {
        newPosition.x = _playerComponent.position.x;
      }
      if (newPosition.y < _playerAreaMargin.y ||
          newPosition.y > size.y - _playerAreaMargin.y) {
        newPosition.y = _playerComponent.position.y;
      }
      _playerComponent.position = newPosition;
    }
    super.update(dt);
  }

  void addGunner({
    required int interval,
    required int exactTiming,
    required AxisDirection entrySide,
    required double xPercentage,
    required double yPercentage,
  }) {
    late Vector2 gunnerStartingPosition;
    switch (entrySide) {
      case AxisDirection.left:
        gunnerStartingPosition =
            Vector2(0, _playerAreaMargin.y + (playAreaSize.y * yPercentage));
        break;
      case AxisDirection.right:
        gunnerStartingPosition = Vector2(
            size.x, _playerAreaMargin.y + (playAreaSize.y * yPercentage));
        break;
      case AxisDirection.up:
        gunnerStartingPosition =
            Vector2(_playerAreaMargin.x + (playAreaSize.x * xPercentage), 0);
        break;
      case AxisDirection.down:
        gunnerStartingPosition = Vector2(
            _playerAreaMargin.x + (playAreaSize.x * xPercentage), size.y);
        break;
    }
    final newGunner = UndertaleGunner(
      radius: 20,
      position: gunnerStartingPosition,
      anchor: Anchor.center,
      entrySide: entrySide,
      bulletTravelDistance: size.x - _playerAreaMargin.x,
      expectedTimeOfStart: microsecondsToSeconds(exactTiming),
      beatInterval: microsecondsToSeconds(interval),
    );
    upcomingGunnerQueue.addLast(newGunner);
  }

  @override
  void render(Canvas canvas) {
    // Clip area around the cage.
    final rect = Rect.fromLTWH(
      0,
      0,
      size.x,
      size.y,
    );
    canvas.drawRect(rect, Paint()..color = Colors.transparent);
    canvas.clipRect(rect);
    canvas.save();
    canvas.restore();
    super.render(canvas);
  }
}
