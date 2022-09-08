import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:untitled_rhythm_game/components/games/minigame_type.dart';
import 'package:untitled_rhythm_game/level_constants.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class BeatMap {
  /// Name of the Song this BeatMap represents.
  final String songName;

  /// Name of the artist of this song.
  final String artistName;

  /// The number of microseconds between each beat. Calculated from the [bpm].
  final int beatInterval;

  final Map<String, SpriteReplacementModel> spriteReplacements;

  /// The list of mini-games (in order) that should be played during this song.
  final List<MiniGameModel> gameOrder;

  /// The total number of beats in this song.
  late final int beatTotal;

  /// The song level that this BeatMap maps with.
  late final Level level;

  BeatMap.fromJson(Map<String, dynamic> json, Level level)
      : level = level,
        songName = json["name"],
        artistName = json["artist"],
        beatInterval = bpmToMicroseconds(json["bpm"]),
        spriteReplacements = json["spriteReplacements"] != null
            ? Map.fromIterable(json["spriteReplacements"],
                key: (e) => e["identifier"],
                value: (e) => SpriteReplacementModel.fromJson(e))
            : {},
        gameOrder = json["gameOrder"]
            .map<MiniGameModel>((gameJson) => MiniGameModel.fromJson(gameJson))
            .toList() {
    // Calculate beat total.
    int beatCount = 0;
    gameOrder.forEach((game) {
      beatCount += game.beats.length;
    });
    beatTotal = beatCount;
  }

  static Future<BeatMap> loadFromLevel(Level level) async {
    String beatMapPath = getLevelBeatMapPath(level);
    String jsonString = await rootBundle.loadString(beatMapPath);
    return BeatMap.fromJson(json.decode(jsonString), level);
  }
}

class SpriteReplacementModel {
  /// Path to the sprite asset.
  final String path;

  /// (For GIFs) Number of frames in the sprite sheet.
  final int frames;

  /// Sprite width in pixels.
  final double pixelsX;

  /// Sprite height in pixels.
  final double pixelsY;

  /// (For GIFs) Time (in seconds) between each frame.
  final double stepTime;

  SpriteReplacementModel.fromJson(Map<String, dynamic> json)
      : path = json["path"],
        frames = json["frames"] ?? 0,
        pixelsX = json["pixelsX"] ?? 0.0,
        pixelsY = json["pixelsY"] ?? 0.0,
        stepTime = json["stepTime"] ?? 0.0;
}

class MiniGameModel {
  /// The specific mini-game.
  final MiniGameType gameType;

  /// The list BeatModels representing each beat and all notes contained in each beat.
  final List<BeatModel> beats;

  MiniGameModel.fromJson(Map<String, dynamic> json)
      : gameType = miniGameTypeFromString(json["game"]),
        beats = json["beats"]
            .map<BeatModel>((beatJson) => BeatModel.fromJson(beatJson))
            .toList();

  MiniGameModel.gameStartTransition()
      : gameType = MiniGameType.gameTransition,
        beats = _generateEmptyBeats(8);

  static List<BeatModel> _generateEmptyBeats(int count) {
    final List<BeatModel> beats = [];
    for (int i = 0; i < count; i++) {
      beats.add(BeatModel.fromJson([Map<String, dynamic>()]));
    }
    return beats;
  }
}

class BeatModel {
  final List<NoteModel> notes;

  BeatModel.fromJson(List<dynamic> jsonList)
      : notes = jsonList
            .map<NoteModel>((noteJson) => NoteModel.fromJson(noteJson))
            .toList();
}

class NoteModel {
  final double timing;
  final double duration; // in percentage of beat interval.
  final int column;
  final double posX;
  final double posY;
  final String label;

  NoteModel.fromJson(Map<String, dynamic> json)
      : timing = json["timing"] ?? 0,
        duration = json["duration"] ?? 0,
        column = json["column"] ?? 0,
        posX = double.tryParse(json["posX"].toString()) ?? 0.0,
        posY = double.tryParse(json["posY"].toString()) ?? 0.0,
        label = json["label"] ?? "";
}
