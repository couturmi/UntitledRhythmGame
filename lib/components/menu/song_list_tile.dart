import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/mixins/game_size_aware.dart';
import 'package:untitled_rhythm_game/level_constants.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';

class SongListTile extends PositionComponent with TapCallbacks, GameSizeAware {
  static const double xPadding = 20.0;
  static const double yPadding = 10.0;

  final int index;
  final Level level;
  final Function(SongListTile tile) onTap;

  late final BeatMap _beatMap;
  late final RectangleComponent _tileBackground;
  late final TextComponent _songTitle;

  bool activated = false;

  SongListTile({required this.index, required this.level, required this.onTap});

  @override
  Future<void> onLoad() async {
    super.onLoad();
    anchor = Anchor.topLeft;
    size = Vector2(gameSize.x - (xPadding * 2), 80 - (yPadding * 2));
    _beatMap = await BeatMap.loadFromLevel(level);
    position = 
        Vector2(0 + xPadding, (80 + yPadding) + (index * (size.y + yPadding)));
    addAll([
      RectangleComponent(
        priority: 1,
        size: size,
        paint: Paint()
          ..color = Colors.grey
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      ),
      _tileBackground = RectangleComponent(
        priority: 0,
        size: size,
        paint: Paint()..color = Colors.black,
      ),
      _songTitle = TextComponent(
        priority: 2,
        text: _beatMap.songName,
        textRenderer: TextPaint(style: _getTextStyle(Colors.white)),
        position: Vector2(15, size.y / 2),
        anchor: Anchor.centerLeft,
      ),
    ]);
  }

  activate() {
    activated = true;
    _tileBackground.paint.color = Colors.teal.withOpacity(0.3);
    _songTitle.textRenderer = TextPaint(style: _getTextStyle(Colors.yellow));
  }

  deactivate() {
    activated = false;
    _tileBackground.paint.color = Colors.black;
    _songTitle.textRenderer = TextPaint(style: _getTextStyle(Colors.white));
  }

  static TextStyle _getTextStyle(Color color) {
    return TextStyle(color: color, fontSize: 26);
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    if (!activated) {
      // Set the tile properties as activated.
      FlameAudio.play('effects/selection.mp3');
      activate();
      // Execute parent functionality.
      this.onTap(this, _beatMap);
    }
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    this.onResize(gameSize);
  }
}
