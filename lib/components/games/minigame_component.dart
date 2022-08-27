import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';
import 'package:untitled_rhythm_game/song_level_component.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

abstract class MiniGameComponent extends PositionComponent {
  /// Model representing the basic data for this mini-game.
  final MiniGameModel model;

  /// Length (in microseconds) of a single beat.
  final int beatInterval;

  /// Current beat count within the current mini-game.
  int miniGameBeatCount = 0;

  BeatModel get thisBeat => model.beats[miniGameBeatCount];

  bool get isLastBeat => model.beats.length - 1 <= miniGameBeatCount;

  MiniGameComponent({required this.model, required this.beatInterval})
      : super(priority: 1);

  /// Handle a note coming in.
  ///
  /// [exactTiming]: exact timing {in microseconds) that the note should start (from the start of the song).
  /// [noteModel]: contains specifics about this note.
  void handleNote({
    required int exactTiming,
    required NoteModel noteModel,
  });

  void handleUpcomingBeat({required int songBeatCount}) {
    // TODO "This" beat might cause funky things to happen if there is a lot of lagging. You should pass the currentBeatCount in to check if multiple beats should be added/updated.
    thisBeat.notes.forEach((note) {
      handleNote(
          exactTiming: (songBeatCount * beatInterval) +
              (beatInterval * note.timing).round(),
          noteModel: note);
    });
    miniGameBeatCount++;
  }

  @override
  void update(double dt) {
    // Check if the lifetime of this mini-game has ended.
    // If so, remove from parent.
    if (miniGameBeatCount >= model.beats.length) {
      miniGameBeatCount = -1;
      add(RemoveEffect(
          delay: microsecondsToSeconds(beatInterval *
              (SongLevelComponent.INTERVAL_TIMING_MULTIPLIER + 1))));
    }
    super.update(dt);
  }
}
