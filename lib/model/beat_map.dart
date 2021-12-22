import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

class BeatMap {
  final String songName;
  final String artistName;
  final int bpm;
  final List<BeatModel> beats;

  BeatMap.fromJson(Map<String, dynamic> json)
      : songName = json["name"],
        artistName = json["artist"],
        bpm = json["bpm"],
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
