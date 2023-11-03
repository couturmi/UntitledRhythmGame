import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:untitled_rhythm_game/components/games/landscape_minigame_component.dart';

/// Alternative to using [HasGameRef] to get the canvas size, specifically for
/// components that are part of a song level (that changes orientation)
mixin LevelSizeAware<T extends FlameGame> on HasGameRef<T> {
  late Vector2 levelSize;
  bool? _isLandscapeModeGame;

  /// Checks if a parent exists that is a [LandscapeMiniGameComponent].
  bool get isLandscapeModeGame {
    if (_isLandscapeModeGame == null) {
      Component? c = this;
      while (c != null) {
        if (c != this && c is LevelSizeAware) {
          _isLandscapeModeGame = c.isLandscapeModeGame;
          return _isLandscapeModeGame!;
        } else if (c is LandscapeMiniGameComponent) {
          _isLandscapeModeGame = true;
          return _isLandscapeModeGame!;
        } else {
          c = c.parent;
        }
      }
      _isLandscapeModeGame = false;
    }
    return _isLandscapeModeGame!;
  }

  /// Sets the stored [levelSize] based on the orientation of the component.
  void setLevelSize() {
    final newGameSize = super.game.size;
    // If this component is within a landscape game element, flip the x and y.
    if (isLandscapeModeGame) {
      levelSize = Vector2(newGameSize.y, newGameSize.x);
    } else {
      levelSize = newGameSize;
    }
  }
}
