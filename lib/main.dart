import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'dart:async' as Async;
import 'package:untitled_rhythm_game/components/backdrops/megalovania/gooter_dancing_component.dart';
import 'package:untitled_rhythm_game/components/games/taptap/taptap_grid.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class MyGame extends FlameGame with HasTappables {
  static const int AUDIO_DELAY_MICROSECONDS = 300000; // was 250000
  int beatCount = 0;

  @override
  Future<void> onLoad() async {
    // Load song BeatMap.
    BeatMap beatMap =
        await BeatMap.loadFromFile("assets/beat_maps/megalovania.json");
    int interval = bpmToMicroseconds(beatMap.bpm);
    // add background.
    final gooterBackgroundComponent =
        GooterDancingComponent(interval: interval);
    await add(gooterBackgroundComponent);
    // add game.
    final gameComponent = TapTapGridComponent();
    await add(gameComponent);
    // Set up timer
    await FlameAudio.audioCache.load('music/megalovania.mp3');
    // set delay for when game should start.
    Async.Timer(Duration(seconds: 1), () {
      // set delay for when music should start playing.
      Async.Timer(Duration(microseconds: interval * 2), () {
        FlameAudio.playLongAudio('music/megalovania.mp3');
      });
      // Wrap in a one-time delay to account for the music start-delay
      Async.Timer(Duration(microseconds: AUDIO_DELAY_MICROSECONDS), () {
        // load first beat sequence
        addNotesForBeat(gameComponent, beatMap, interval);
        beatCount++;
        Async.Timer(Duration(microseconds: interval), () {
          // load second beat sequence
          addNotesForBeat(gameComponent, beatMap, interval);
          beatCount++;
          Async.Timer(Duration(microseconds: interval), () {
            // load third beat sequence
            addNotesForBeat(gameComponent, beatMap, interval);
            beatCount++;
            Async.Timer.periodic(Duration(microseconds: interval), (timer) {
              gooterBackgroundComponent.beatUpdate();
              // load next beat sequence
              addNotesForBeat(gameComponent, beatMap, interval);
              beatCount++;
            });
          });
        });
      });
    });
    await super.onLoad();
  }

  void addNotesForBeat(
      TapTapGridComponent taptapGrid, BeatMap beatMap, int interval) {
    if (beatCount < beatMap.beats.length) {
      beatMap.beats[beatCount].notes.forEach((note) {
        taptapGrid.addNote(
            columnIndex: note.column,
            interval: interval,
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
