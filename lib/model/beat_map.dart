import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:untitled_rhythm_game/components/games/minigame_type.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class BeatMap {
  /// Name of the Song this BeatMap represents.
  final String songName;

  /// Name of the artist of this song.
  final String artistName;

  /// The number of microseconds between each beat. Calculated from the [bpm].
  final int beatInterval;

  /// The list of mini-games (in order) that should be played during this song.
  final List<MiniGameModel> gameOrder;

  /// The total number of beats in this song.
  late final int beatTotal;

  BeatMap.fromJson(Map<String, dynamic> json)
      : songName = json["name"],
        artistName = json["artist"],
        beatInterval = bpmToMicroseconds(json["bpm"]),
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

  static Future<BeatMap> loadFromFile(String path) async {
    String jsonString = await rootBundle.loadString(path);
    return BeatMap.fromJson(json.decode(jsonString));
  }
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
  final int column;
  final double posX;
  final double posY;

  NoteModel.fromJson(Map<String, dynamic> json)
      : timing = json["timing"] ?? 0,
        column = json["column"] ?? 0,
        posX = double.tryParse(json["posX"].toString()) ?? 0.0,
        posY = double.tryParse(json["posY"].toString()) ?? 0.0;
}
