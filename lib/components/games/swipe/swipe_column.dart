import 'dart:collection';

import 'package:flame/components.dart';
import 'package:untitled_rhythm_game/components/games/swipe/ship_component.dart';
import 'package:untitled_rhythm_game/components/games/swipe/swipe_game_component.dart';
import 'package:untitled_rhythm_game/components/games/swipe/swipe_obstacle.dart';
import 'package:untitled_rhythm_game/components/mixins/game_size_aware.dart';
import 'package:untitled_rhythm_game/my_game.dart';
import 'package:untitled_rhythm_game/song_level_component.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class SwipeColumn extends PositionComponent
    with GameSizeAware, HasGameRef<MyGame> {
  /// Column placement in board (from the left).
  final int columnIndex;

  /// Queue for obstacles that are currently displayed and able to be hit.
  final Queue<SwipeObstacle> obstacleQueue = Queue();

  /// Queue for obstacles that are yet to be displayed and are waiting for the exact timing.
  final Queue<SwipeObstacle> upcomingObstacleQueue = Queue();

  /// Determines the priority of the next obstacle to display, so that is is always
  /// visually in front of the obstacle after it.
  int nextObstaclePriority = 999;

  SwipeColumn({required this.columnIndex});

  @override
  Future<void> onLoad() async {
    anchor = Anchor.topLeft;
    size = Vector2(gameSize.x / SwipeGameComponent.numberOfColumns, gameSize.y);
    super.onLoad();
  }

  @override
  void update(double dt) {
    // Check if any new obstacles need to be added.
    upcomingObstacleQueue.removeWhere((newObstacle) {
      if (newObstacle.expectedTimeOfStart <= gameRef.currentLevel.songTime) {
        obstacleQueue.addFirst(newObstacle);
        add(newObstacle);
        return true;
      }
      return false;
    });
    // Check if any obstacles should be removed.
    obstacleQueue.removeWhere((obstacle) {
      if (obstacle.currentTimingOfObstacle >= obstacle.timeObstacleIsVisible) {
        // If ship did not collide with this obstacle, notify score.
        if (!obstacle.hasCollidedWithShip) {
          gameRef.currentLevel.scoreComponent.avoidedObstacle();
        }
        obstacle.removeFromParent();
        return true;
      }
      return false;
    });
    super.update(dt);
  }

  addObstacle({
    required int exactTiming,
    required int interval,
  }) {
    double fullObstacleTravelDistance =
        gameSize.y + (gameSize.y * SwipeObstacle.obstacleYLengthPercentage);
    double timeObstacleIsVisible = timeForObstacleToTravel(
        fullObstacleTravelDistance / gameSize.y, interval);

    // Create obstacle component.
    final SwipeObstacle obstacle = SwipeObstacle(
      imageWidth: gameSize.x / SwipeGameComponent.numberOfColumns,
      position: Vector2(0, 0),
      expectedTimeOfStart: microsecondsToSeconds(exactTiming),
      fullObstacleTravelDistance: fullObstacleTravelDistance,
      timeObstacleIsVisible: microsecondsToSeconds(timeObstacleIsVisible),
      priority: nextObstaclePriority,
    );
    nextObstaclePriority--;
    upcomingObstacleQueue.addFirst(obstacle);
  }

  /// Calculates the time it should take for an obstacle to travel [yPercentageTarget] percent of the Y-Axis.
  ///
  /// [yPercentageTarget] : percentage of the Y-axis size that the obstacle will have travelled.
  /// [beatInterval] : time it takes for a single beat to complete, in microseconds.
  double timeForObstacleToTravel(double yPercentageTarget, int beatInterval) {
    return ((yPercentageTarget) *
            beatInterval *
            SongLevelComponent.INTERVAL_TIMING_MULTIPLIER) /
        ShipComponent.hitCircleYPlacementModifier;
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    this.onResize(canvasSize);
    position = Vector2(
        (this.gameSize.x / SwipeGameComponent.numberOfColumns) * columnIndex,
        0);
  }
}
