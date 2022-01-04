import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'dart:async' as Async;
import 'package:untitled_rhythm_game/components/backdrops/megalovania/megalovania_background_component.dart';
import 'package:untitled_rhythm_game/components/games/taptap/taptap_board.dart';
import 'package:untitled_rhythm_game/components/games/taptap/taptap_column.dart';
import 'package:untitled_rhythm_game/components/scoring/score_component.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';

class MyGame extends FlameGame with HasTappables {
  static const int AUDIO_DELAY_MICROSECONDS = 300000; // was 250000

  int beatCount = 0;
  late final BeatMap beatMap;
  late final MegalovaniaBackgroundComponent backgroundComponent;
  late final TapTapBoardComponent tapTapBoardComponent;
  late final ScoreComponent scoreComponent;

  @override
  Future<void> onLoad() async {
    // Load song BeatMap.
    beatMap = await BeatMap.loadFromFile("assets/beat_maps/megalovania.json");
    // Preload song.
    await FlameAudio.audioCache.load('music/megalovania.mp3');
    // Set game components.
    setGameComponents();
    // Set delay for when game should start. TODO this will eventually be a button.
    Async.Timer(Duration(seconds: 1), () {
      playSong();
    });
    await super.onLoad();
  }

  void setGameComponents() {
    backgroundComponent =
        MegalovaniaBackgroundComponent(interval: beatMap.beatInterval);
    tapTapBoardComponent = TapTapBoardComponent();
    scoreComponent = ScoreComponent();
    add(backgroundComponent);
    add(tapTapBoardComponent);
    add(scoreComponent);
  }

  /// Play the song and set the timer that occurs every beat.
  void playSong() {
    // set delay for when music should start playing.
    Async.Timer(
        Duration(
            microseconds: beatMap.beatInterval *
                TapTapColumn.intervalTimingMultiplier), () {
      FlameAudio.playLongAudio('music/megalovania.mp3');
    });
    // Wrap in a one-time delay to account for the music start-delay
    Async.Timer(Duration(microseconds: AUDIO_DELAY_MICROSECONDS), () {
      // load first beat sequence
      addNotesForBeat();
      beatCount++;
      Async.Timer.periodic(Duration(microseconds: beatMap.beatInterval),
          (preSongBeatTimer) {
        // load next beat sequences before song begins playing.
        addNotesForBeat();
        if (beatCount == TapTapColumn.intervalTimingMultiplier) {
          preSongBeatTimer.cancel();
          Async.Timer.periodic(Duration(microseconds: beatMap.beatInterval),
              (_) {
            backgroundComponent.beatUpdate();
            // load next beat sequence
            addNotesForBeat();
            beatCount++;
          });
        }
        beatCount++;
      });
    });
  }

  void addNotesForBeat() {
    if (beatCount < beatMap.beats.length) {
      beatMap.beats[beatCount].notes.forEach((note) {
        tapTapBoardComponent.addNote(
            columnIndex: note.column,
            interval: beatMap.beatInterval,
            beatDelay: note.timing);
      });
    }
  }
}

main() {
  final myGame = MyGame();
  runApp(
    GameWidget(
      game: myGame,
    ),
  );
}
