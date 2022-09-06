import 'package:flame/components.dart';
import 'package:untitled_rhythm_game/components/menu/song_list_tile.dart';
import 'package:untitled_rhythm_game/level_constants.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';

class SongListComponent extends PositionComponent {
  final double yOffset;
  final Function(SongListTile tile, BeatMap beatMap) onTileTap;

  SongListComponent({
    required this.yOffset,
    required this.onTileTap,
  });

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = Vector2(0, yOffset);
    // Add tile components.
    List<SongListTile> songList = [];
    // TODO not sure if this is the ideal way to make a list... How would I make it scrollable in the future?
    for (int i = 0; i < Level.values.length; i++) {
      songList.add(
          SongListTile(index: i, level: Level.values[i], onTap: onTileTap));
    }
    addAll([
      ...songList,
    ]);
  }
}
