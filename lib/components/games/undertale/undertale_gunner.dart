import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/games/undertale/undertale_bullet.dart';
import 'package:untitled_rhythm_game/my_game.dart';
import 'package:untitled_rhythm_game/song_level_component.dart';

class UndertaleGunner extends PositionComponent with HasGameRef<MyGame> {
  /// Radius of the gunner sprite
  final double radius;

  /// Time (in seconds) that this component was expected to be loaded.
  final double expectedTimeOfStart;

  /// Side of the cage that the gunner enters from.
  final AxisDirection entrySide;

  /// Distance the bullet should travel before disappearing.
  final double bulletTravelDistance;

  /// Time (in seconds) of a single beat.
  final double beatInterval;

  /// True when the gunner has shot its bullet.
  bool _hasTakenShot;

  /// True when the gunner has retreated.
  bool _isGunnerHidden;

  late final UndertaleBullet _bulletComponent;
  late final SpriteComponent _gunnerSprite;

  UndertaleGunner({
    super.position,
    super.anchor,
    required this.radius,
    required this.expectedTimeOfStart,
    required this.entrySide,
    required this.bulletTravelDistance,
    required this.beatInterval,
  })  : _hasTakenShot = false,
        _isGunnerHidden = false;

  double get currentTimingOfNote =>
      gameRef.currentLevel.songTime - expectedTimeOfStart;

  /// Exact time (in seconds) that the gunner should shoot its bone.
  double get highNoon =>
      beatInterval * SongLevelComponent.INTERVAL_TIMING_MULTIPLIER;

  /// Exact time (in seconds) that the gunner should retreat.
  double get timingOfGunnerRetreat => highNoon + (beatInterval);

  @override
  Future<void> onLoad() async {
    late double gunnerRotation;
    switch (entrySide) {
      case AxisDirection.left:
        gunnerRotation = pi * 1.5;
        break;
      case AxisDirection.right:
        gunnerRotation = pi * 0.5;
        break;
      case AxisDirection.up:
        gunnerRotation = 0;
        break;
      case AxisDirection.down:
        gunnerRotation = pi;
        break;
    }
    angle = gunnerRotation;
    // Add gunner sprite.
    add(_gunnerSprite = SpriteComponent(
        priority: 1,
        sprite: await Sprite.load("dragon.png"),
        size: Vector2.all(radius * 2),
        paint: Paint()
          ..colorFilter =
              ColorFilter.mode(Colors.redAccent, BlendMode.modulate),
        anchor: Anchor.center,
        position: Vector2(0, -radius)));
    _gunnerSprite.add(MoveEffect.to(
        Vector2(0, radius * 0.5), LinearEffectController(beatInterval)));

    // Prepare bullet sprite.
    _bulletComponent = UndertaleBullet(
      priority: 0,
      size: Vector2.all(radius * 2),
      anchor: Anchor.center,
    );
    super.onLoad();
  }

  /// Shoot the bullet obstacle.
  void _shoot() async {
    _hasTakenShot = true;
    add(_bulletComponent);
    _bulletComponent.add(MoveEffect.by(
      Vector2(0, bulletTravelDistance),
      LinearEffectController(
          beatInterval * (SongLevelComponent.INTERVAL_TIMING_MULTIPLIER + 1)),
    )
      // remove when bullet has reached end
      ..onComplete = () {
        _fadeAndRemove();
      });
  }

  /// Hide the gunner sprite from view.
  void _retreat() {
    _isGunnerHidden = true;
    _gunnerSprite.add(MoveEffect.to(
      Vector2(0, -radius),
      LinearEffectController(beatInterval),
    ));
  }

  /// Fade the bullet away and remove component.
  void _fadeAndRemove() {
    _bulletComponent.fadeOut(0.1);
    add(RemoveEffect(delay: 0.1)
      ..onComplete = () {
        if (!_bulletComponent.hasCollidedWithPlayer) {
          gameRef.currentLevel.scoreComponent.avoidedObstacle();
        }
      });
  }

  @override
  void update(double dt) {
    if (!_hasTakenShot && currentTimingOfNote >= highNoon) {
      _shoot();
    }
    if (!_isGunnerHidden && currentTimingOfNote >= timingOfGunnerRetreat) {
      _retreat();
    }
    super.update(dt);
  }
}
