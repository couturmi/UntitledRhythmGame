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

  // TODO interval should not be required. It is static and retrievable from the song component.
  /// Handle a note coming in.
  ///
  /// [exactTiming]: exact timing {in microseconds) that the note should start (from the start of the song).
  /// [interval]: length (in microseconds) of a single beat.
  /// [noteModel]: contains specifics about this note.
  void handleNote({
    required int exactTiming,
    required int interval,
    required NoteModel noteModel,
  });
}
