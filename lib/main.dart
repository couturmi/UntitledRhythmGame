import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'dart:async' as Async;
import 'package:untitled_rhythm_game/components/backdrops/megalovania/megalovania_background_component.dart';
import 'package:untitled_rhythm_game/components/games/taptap/taptap_board.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';

class MyGame extends FlameGame with HasTappables {
  static const int AUDIO_DELAY_MICROSECONDS = 300000; // was 250000

  int beatCount = 0;
  late final BeatMap beatMap;
  late final MegalovaniaBackgroundComponent backgroundComponent;
  late final TapTapBoardComponent tapTapBoardComponent;

  @override
  Future<void> onLoad() async {
    // Load song BeatMap.
    beatMap = await BeatMap.loadFromFile("assets/beat_maps/megalovania.json");
    // Preload song.
    await FlameAudio.audioCache.load('music/megalovania.mp3');
    // Set game components.
    await setGameComponents();
    // Set delay for when game should start. TODO this will eventually be a button.
    Async.Timer(Duration(seconds: 1), () {
      playSong();
    });
    await super.onLoad();
  }

  Future<void> setGameComponents() async {
    backgroundComponent =
        MegalovaniaBackgroundComponent(interval: beatMap.beatInterval);
    tapTapBoardComponent = TapTapBoardComponent();
    // Note: add order is very important here, hence the "await" for each.
    await add(backgroundComponent);
    await add(tapTapBoardComponent);
    // TODO add overlay component
  }

  /// Play the song and set the timer that occurs every beat.
  void playSong() {
    // set delay for when music should start playing.
    Async.Timer(Duration(microseconds: beatMap.beatInterval * 2), () {
      FlameAudio.playLongAudio('music/megalovania.mp3');
    });
    // Wrap in a one-time delay to account for the music start-delay
    Async.Timer(Duration(microseconds: AUDIO_DELAY_MICROSECONDS), () {
      // load first beat sequence
      addNotesForBeat();
      beatCount++;
      Async.Timer(Duration(microseconds: beatMap.beatInterval), () {
        // load second beat sequence
        addNotesForBeat();
        beatCount++;
        Async.Timer(Duration(microseconds: beatMap.beatInterval), () {
          // load third beat sequence
          addNotesForBeat();
          beatCount++;
          Async.Timer.periodic(Duration(microseconds: beatMap.beatInterval),
              (timer) {
            backgroundComponent.beatUpdate();
            // load next beat sequence
            addNotesForBeat();
            beatCount++;
          });
        });
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
