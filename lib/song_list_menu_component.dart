import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:untitled_rhythm_game/components/menu/play_button.dart';
import 'package:untitled_rhythm_game/components/menu/song_list_tile.dart';
import 'package:untitled_rhythm_game/components/mixins/game_size_aware.dart';
import 'package:untitled_rhythm_game/level_constants.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';
import 'package:untitled_rhythm_game/my_game.dart';

class SongListMenuComponent extends Component
    with HasGameRef<MyGame>, GameSizeAware {
  static SongListTile? _selectedSongTile;
  static BeatMap? _selectedBeatMap;
  late final PlayButton _playButton;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Preload all song previews.
    Level.values.forEach((level) {
      FlameAudio.audioCache.load(getLevelMP3PreviewPathMap(level));
    });
    FlameAudio.audioCache.load('effects/selection.mp3');
    // Add components.
    List<SongListTile> songList = [];
    // TODO not sure if this is the ideal way to make a list... How would I make it scrollable in the future?
    for (int i = 0; i < Level.values.length; i++) {
      songList.add(SongListTile(
          index: i, level: Level.values[i], onTap: _onSongTileTap));
    }
    addAll([
      TextComponent(
        text: "Song List",
        textRenderer: TextPaint(
            style: TextStyle(
                fontFamily: 'Courier', color: Colors.teal, fontSize: 36)),
        anchor: Anchor.center,
        position: Vector2(gameSize.x / 2, 50),
      ),
      ...songList,
    ]);
    _playButton = PlayButton(
      anchor: Anchor.center,
      position: Vector2(gameSize.x / 2, gameSize.y - 100),
      onButtonTap: playSong,
    );
  }

  /// Called when a tile is tapped from the song list.
  void _onSongTileTap(SongListTile tile, BeatMap beatMap) async {
    // Deactivate previous tile.
    _selectedSongTile?.deactivate();
    // Update selected song info and show start button.
    _selectedSongTile = tile;
    _selectedBeatMap = beatMap;
    if (!contains(_playButton)) {
      add(_playButton);
    }
    // Play song preview.
    FlameAudio.bgm.play(getLevelMP3PreviewPathMap(tile.level));
  }

  /// Play the selected [_selectedBeatMap] song level.
  void playSong() {
    FlameAudio.play('effects/button_click.mp3');
    FlameAudio.bgm.pause();
    gameRef.startSongLevel(_selectedBeatMap!);
    // TODO, eventually set the above route to a ValueRoute, so that you can resume the music when returning to the menu.
  }

  @override
  void onGameResize(Vector2 canvasSize) {
    super.onGameResize(canvasSize);
    this.onResize(canvasSize);
  }
}
