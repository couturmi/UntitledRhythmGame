import 'dart:collection';

import 'package:flame/components.dart';
import 'package:untitled_rhythm_game/components/games/swipe/ship_component.dart';
import 'package:untitled_rhythm_game/components/games/swipe/swipe_game_component.dart';
import 'package:untitled_rhythm_game/components/games/swipe/swipe_obstacle.dart';
import 'package:untitled_rhythm_game/components/mixins/level_size_aware.dart';
import 'package:untitled_rhythm_game/my_game.dart';
import 'package:untitled_rhythm_game/components/level/song_level_component.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class SwipeColumn extends PositionComponent
    with HasGameRef<MyGame>, LevelSizeAware {
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
    setLevelSize();
    anchor = Anchor.topLeft;
    position = Vector2(
        (this.levelSize.x / SwipeGameComponent.numberOfColumns) * columnIndex,
        0);
    size =
        Vector2(levelSize.x / SwipeGameComponent.numberOfColumns, levelSize.y);
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
        levelSize.y + (levelSize.y * SwipeObstacle.obstacleYLengthPercentage);
    double timeObstacleIsVisible = timeForObstacleToTravel(
        fullObstacleTravelDistance / levelSize.y, interval);

    // Create obstacle component.
    final SwipeObstacle obstacle = SwipeObstacle(
      imageWidth: levelSize.x / SwipeGameComponent.numberOfColumns,
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
}
