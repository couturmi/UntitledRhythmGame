import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/games/minigame_component.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';
import 'package:untitled_rhythm_game/song_level_component.dart';

class GameTransitionComponent extends MiniGameComponent {
  late final Component title;
  late final Component subTitle;

  GameTransitionComponent(MiniGameModel model) : super(model: model);

  @override
  Future<void> onLoad() async {
    title = TextComponent(
      text: "N E X T   U P",
      textRenderer: TextPaint(
          style: TextStyle(
              color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
      position: Vector2(0, -50),
      anchor: Anchor.center,
    );
    subTitle = TextComponent(
      text: "TAP TAP",
      textRenderer: TextPaint(
          style: TextStyle(
              color: Colors.white, fontSize: 72, fontWeight: FontWeight.bold)),
      position: Vector2(0, 10),
      anchor: Anchor.center,
    );
    super.onLoad();
  }

  @override
  void handleNote({required int interval, required NoteModel noteModel}) {
    // Only show transition animation after the interval timing delay.
    if (miniGameBeatCount == SongLevelComponent.INTERVAL_TIMING_MULTIPLIER) {
      add(title);
    }
    if (miniGameBeatCount ==
        SongLevelComponent.INTERVAL_TIMING_MULTIPLIER * 2) {
      add(subTitle);
    }
    // And hide transition before the next mini-game would start displaying
    else if (model.beats.length -
            SongLevelComponent.INTERVAL_TIMING_MULTIPLIER ==
        miniGameBeatCount - 1) {
      removeAll(children);
    }
  }

  @override
  void onGameResize(Vector2 gameSize) {
    super.onGameResize(gameSize);
    position = gameSize / 2;
  }
}
