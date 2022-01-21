import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'dart:async' as Async;
import 'package:untitled_rhythm_game/components/backdrops/megalovania/megalovania_background_component.dart';
import 'package:untitled_rhythm_game/components/games/minigame_component.dart';
import 'package:untitled_rhythm_game/components/games/minigame_type.dart';
import 'package:untitled_rhythm_game/components/games/osu/osu_game_component.dart';
import 'package:untitled_rhythm_game/components/games/taptap/taptap_board.dart';
import 'package:untitled_rhythm_game/components/games/tilt/tilt_game_component.dart';
import 'package:untitled_rhythm_game/components/games/transition/minigame_transition_component.dart';
import 'package:untitled_rhythm_game/components/mixins/game_size_aware.dart';
import 'package:untitled_rhythm_game/components/scoring/score_component.dart';
import 'package:untitled_rhythm_game/level_constants.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';
import 'package:audioplayers/audioplayers.dart';

class SongLevelComponent extends PositionComponent with GameSizeAware {
  static const int AUDIO_DELAY_MICROSECONDS =
      250000; // was 250000 // was 300000

  /// The number of beat intervals it should take a note from creation to reach the hit mark.
  /// TODO 2 = hard, 3 = medium, 4 = easy
  static const int INTERVAL_TIMING_MULTIPLIER = 2;

  final Level songLevel;

  /// Index of the current mini-game being played. Value is -1 when no games have started.
  late int currentMiniGameIndex = -1;

  /// The number of intervals left until the previous mini-game should be removed from view.
  /// Once the value reaches 0, the previous mini-game will be removed.
  int removePreviousMiniGameCountDown = -1;

  /// Current beat count for the entire song.
  /// Note that this does NOT the represent the current beat playing in the audio, instead it is
  /// the current beat that is being loaded.
  int _currentBeatCount = 0;

  /// Current orientation that the level is set to.
  DeviceOrientation currentLevelOrientation = DeviceOrientation.portraitUp;

  late final BeatMap _beatMap;
  late AudioPlayer _audioPlayer;

  late final MegalovaniaBackgroundComponent backgroundComponent;
  late final ScoreComponent scoreComponent;
  late MiniGameComponent currentGameComponent;
  late MiniGameComponent previousGameComponent;

  SongLevelComponent({required this.songLevel});

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Load song BeatMap.
    _beatMap = await BeatMap.loadFromFile(getLevelBeatMapPath(songLevel));
    // Set game components.
    setGameComponents();
    // Start level.
    startLevel();
  }

  void setGameComponents() {
    backgroundComponent =
        MegalovaniaBackgroundComponent(interval: _beatMap.beatInterval);
    scoreComponent = ScoreComponent();
    add(backgroundComponent);
    add(scoreComponent);
    setStartingTransition();
  }

  /// Set the starting MiniGame transition that introduces the first MiniGame.
  void setStartingTransition() {
    currentGameComponent = GameTransitionComponent(
      MiniGameModel.gameStartTransition(),
      nextMiniGameType: _beatMap.gameOrder[0].gameType,
      isStartingTransition: true,
    );
    add(currentGameComponent);
  }

  /// Queue up the next mini-game.
  void queueUpNextMiniGame() {
    // Set a countdown to remove the current mini-game component.
    removePreviousMiniGameCountDown = INTERVAL_TIMING_MULTIPLIER;
    previousGameComponent = currentGameComponent;

    // Set up the next mini-game as the current component.

    currentMiniGameIndex++;
    if (_beatMap.gameOrder.length > currentMiniGameIndex) {
      MiniGameModel nextMiniGameModel =
          _beatMap.gameOrder[currentMiniGameIndex];
      switch (nextMiniGameModel.gameType) {
        case MiniGameType.gameTransition:
          currentGameComponent = GameTransitionComponent(
            nextMiniGameModel,
            nextMiniGameType:
                _beatMap.gameOrder[currentMiniGameIndex + 1].gameType,
          );
          break;
        case MiniGameType.tapTap:
          currentGameComponent = TapTapBoardComponent(nextMiniGameModel);
          break;
        case MiniGameType.osu:
          currentGameComponent = OsuGameComponent(nextMiniGameModel);
          break;
        case MiniGameType.tilt:
          currentGameComponent = TiltGameComponent(nextMiniGameModel);
          break;
      }
      add(currentGameComponent);
    }
  }

  /// Clean up any components that should no longer be in view.
  /// NOTE TODO: This should be handled by individual child components once they each have their own "update" handling.
  void componentCleanUp() {
    if (removePreviousMiniGameCountDown == 0) {
      remove(previousGameComponent);
    }
    removePreviousMiniGameCountDown--;
  }

  /// Start the level.
  /// 1. Show the introduction.
  /// 2. Play the song.
  void startLevel() {
    // Show the starting transition for the game type.
    Async.Timer.periodic(Duration(microseconds: _beatMap.beatInterval),
        (gameIntroTimer) {
      currentGameComponent.thisBeat.notes.forEach((note) {
        currentGameComponent.handleNote(
            interval: _beatMap.beatInterval, noteModel: note);
      });
      if (currentGameComponent.isLastBeat) {
        // Start the song.
        queueUpNextMiniGame();
        playSong();
        gameIntroTimer.cancel();
      } else {
        currentGameComponent.miniGameBeatCount++;
      }
    });
  }

  /// Play the song and set the timer that occurs every beat.
  void playSong() {
    // set delay for when music should start playing.
    Async.Timer(
        Duration(
            microseconds: _beatMap.beatInterval * INTERVAL_TIMING_MULTIPLIER),
        () async {
      _audioPlayer =
          await FlameAudio.playLongAudio(getLevelMP3PathMap(songLevel));
    });
    // Wrap in a one-time delay to account for the music start-delay
    Async.Timer(Duration(microseconds: AUDIO_DELAY_MICROSECONDS), () {
      // Set timer to handle each beat.
      Async.Timer.periodic(Duration(microseconds: _beatMap.beatInterval), (_) {
        // Clean up any components that should no longer be in view.
        componentCleanUp();
        // Handle the beat.
        backgroundComponent.beatUpdate();
        handleBeat();
      });
      // Load first beat.
      handleBeat();
    });
  }

  /// Execute a beat update for the game component.
  void handleBeat() {
    if (_currentBeatCount < _beatMap.beatTotal) {
      // Handle each note that occurs during this beat.
      currentGameComponent.thisBeat.notes.forEach((note) {
        currentGameComponent.handleNote(
            interval: _beatMap.beatInterval, noteModel: note);
      });
      // Check if if a new mini-game should be queued up for the next beat.
      if (currentGameComponent.isLastBeat) {
        queueUpNextMiniGame();
      } else {
        currentGameComponent.miniGameBeatCount++;
      }
    }
    _currentBeatCount++;
  }

  void rotateLevel(DeviceOrientation orientation) {
    currentLevelOrientation = orientation;
    late Vector2 newGameSize;
    late double rotationAngle;
    if (orientation == DeviceOrientation.landscapeLeft) {
      rotationAngle = pi / 2;
      newGameSize = Vector2(gameSize.y, gameSize.x);
    } else if (orientation == DeviceOrientation.landscapeRight) {
      rotationAngle = -pi / 2;
      newGameSize = Vector2(gameSize.y, gameSize.x);
    } else {
      rotationAngle = 0.0;
      newGameSize = gameSize;
    }
    // Rotate entire level component.
    angle = rotationAngle;
    // Resize/Rebuild any components that depend on the gameSize
    scoreComponent.onGameResize(newGameSize);
  }

  @override
  void onRemove() {
    super.onRemove();
    _audioPlayer.stop();
  }

  @override
  void onGameResize(Vector2 gameSize) {
    this.onResize(gameSize);
    anchor = Anchor.center;
    size = gameSize;
    position = gameSize / 2;
    super.onGameResize(gameSize);
  }
}
