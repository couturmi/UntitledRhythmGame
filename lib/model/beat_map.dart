import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:untitled_rhythm_game/util/time_utils.dart';

class BeatMap {
  /// Name of the Song this BeatMap represents.
  final String songName;

  /// Name of the artist of this song.
  final String artistName;

  /// The number of microseconds between each beat. Calculated from the [bpm].
  final int beatInterval;

  /// The list BeatModels representing each beat and all notes contained in each beat.
  final List<BeatModel> beats;

  BeatMap.fromJson(Map<String, dynamic> json)
      : songName = json["name"],
        artistName = json["artist"],
        beatInterval = bpmToMicroseconds(json["bpm"]),
        beats = json["beats"]
            .map<BeatModel>((beatJson) => BeatModel.fromJson(beatJson))
            .toList();

  static Future<BeatMap> loadFromFile(String path) async {
    String jsonString = await rootBundle.loadString(path);
    return BeatMap.fromJson(json.decode(jsonString));
  }
}

class BeatModel {
  final List<NoteModel> notes;

  BeatModel.fromJson(Map<String, dynamic> json)
      : notes = json["notes"]
            .map<NoteModel>((noteJson) => NoteModel.fromJson(noteJson))
            .toList();
}

class NoteModel {
  final double timing;
  final int column;

  NoteModel.fromJson(Map<String, dynamic> json)
      : timing = json["timing"],
        column = json["column"];
}
