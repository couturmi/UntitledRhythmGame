import 'package:flame/components.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';

abstract class MiniGameComponent extends PositionComponent {
  /// Model representing the basic data for this mini-game.
  MiniGameModel model;

  /// Current beat count within the current mini-game.
  int miniGameBeatCount = 0;

  BeatModel get thisBeat => model.beats[miniGameBeatCount];

  bool get isLastBeat => model.beats.length - 1 <= miniGameBeatCount;

  MiniGameComponent({required this.model}) : super(priority: 1);

  void handleNote({required int interval, required NoteModel noteModel});
}
