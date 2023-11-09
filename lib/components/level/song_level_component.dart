import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/services.dart';
import 'package:untitled_rhythm_game/components/backdrops/level_background_component.dart';
import 'package:untitled_rhythm_game/components/games/minigame_component.dart';
import 'package:untitled_rhythm_game/components/games/minigame_type.dart';
import 'package:untitled_rhythm_game/components/games/osu/osu_game_component.dart';
import 'package:untitled_rhythm_game/components/games/slide/slide_game_component.dart';
import 'package:untitled_rhythm_game/components/games/swipe/swipe_game_component.dart';
import 'package:untitled_rhythm_game/components/games/taptap/taptap_board.dart';
import 'package:untitled_rhythm_game/components/games/taptap/taptap_landscape/taptap_landscape_board.dart';
import 'package:untitled_rhythm_game/components/games/tilt/tilt_game_component.dart';
import 'package:untitled_rhythm_game/components/games/transition/minigame_transition_component.dart';
import 'package:untitled_rhythm_game/components/games/undertale/undertale_game_component.dart';
import 'package:untitled_rhythm_game/components/level/level_loading_component.dart';
import 'package:untitled_rhythm_game/components/scoring/score_component.dart';
import 'package:untitled_rhythm_game/components/level/level_constants.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';
import 'package:untitled_rhythm_game/off_beat_game.dart';
import 'package:untitled_rhythm_game/components/level/song_level_complete_component.dart';
import 'package:untitled_rhythm_game/util/on_beat_timer.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class SongLevelComponent extends PositionComponent
    with HasGameRef<OffBeatGame> {
  /// The number of beat intervals it should take a note from creation to reach the hit mark.
  /// TODO 2 = hard, 3 = medium, 4 = easy
  static const int INTERVAL_TIMING_MULTIPLIER = 2;

  final BeatMap beatMap;

  /// Index of the current mini-game being played. Value is -1 when no games have started.
  late int currentMiniGameIndex = -1;

  /// Current beat count for the entire level.
  /// Note that this does NOT the represent the current beat playing in the audio, instead it is
  /// the current beat in the level that is being loaded.
  int _currentLevelBeatCount = 0;

  /// Current beat count for the song duration.
  /// Note that this does NOT the represent the current beat playing in the audio, instead it is
  /// the current beat in the song duration that is being loaded.
  int get _currentSongBeatCount =>
      _currentLevelBeatCount - beatsAtStartBeforeAudioPlays;

  /// Represents the current state of the level setup.
  LevelState levelState = LevelState.notStarted;

  /// Time (in seconds) from the start of the level. (The start of the first transition)
  double levelTime = 0.0;

  /// Time (in seconds) from the start of the music playing.
  double get songTime =>
      levelTime - microsecondsToSeconds(timeAtStartBeforeAudioPlays);

  /// Timer that is called on each beat of the song. This Timer is tied to the game clock.
  late Timer _beatTimer;

  /// Current orientation that the level is set to.
  DeviceOrientation currentLevelOrientation = DeviceOrientation.portraitUp;

  late OnBeatAudioPlayer _audioPlayer = OnBeatAudioPlayer();

  late final LevelLoadingComponent loadingComponent;
  late final LevelBackgroundComponent backgroundComponent;
  late final ScoreComponent scoreComponent;
  late MiniGameComponent currentGameComponent;
  late MiniGameComponent previousGameComponent;

  SongLevelComponent({required this.beatMap});

  int get beatsAtStartBeforeAudioPlays =>
      INTERVAL_TIMING_MULTIPLIER +
      GameTransitionComponent.TRANSITION_BEAT_COUNT;

  /// Time (in microseconds) from when the level starts to when the audio starts.
  int get timeAtStartBeforeAudioPlays =>
      beatsAtStartBeforeAudioPlays * beatMap.beatInterval;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    anchor = Anchor.center;
    size = game.size;
    position = game.size / 2;
    loadingComponent = LevelLoadingComponent();
    add(loadingComponent);
    // Set game components.
    _beatTimer = Timer(
      microsecondsToSeconds(beatMap.beatInterval),
      repeat: true,
      onTick: () {
        this.handleBeat();
      },
    );
    // Print out BeatMap info for debugging.
    print("Beats: ${beatMap.beatTotal}");
    print("BPM (microseconds): ${beatMap.beatInterval}");
    // Clear existing audio cache and preload song.
    _setupMusicAudio();
  }

  Future<void> setGameComponents() async {
    backgroundComponent = getLevelBackgroundComponent(
        level: beatMap.level, interval: beatMap.beatInterval);
    scoreComponent = ScoreComponent();
    await add(backgroundComponent);
    await add(scoreComponent);
    await setStartingTransition();
    levelState = LevelState.readyToStart;
  }

  /// Set the starting MiniGame transition that introduces the first MiniGame.
  Future<void> setStartingTransition() async {
    remove(loadingComponent);
    currentGameComponent = GameTransitionComponent(
      model: MiniGameModel.gameStartTransition(),
      beatInterval: beatMap.beatInterval,
      nextMiniGameType: beatMap.gameOrder[0].gameType,
      isStartingTransition: true,
    );
    await add(currentGameComponent);
  }

  /// Queue up the next mini-game.
  void queueUpNextMiniGame() {
    // Set up the next mini-game as the current component.
    currentMiniGameIndex++;
    if (beatMap.gameOrder.length > currentMiniGameIndex) {
      MiniGameModel nextMiniGameModel = beatMap.gameOrder[currentMiniGameIndex];
      switch (nextMiniGameModel.gameType) {
        case MiniGameType.gameTransition:
          currentGameComponent = GameTransitionComponent(
            model: nextMiniGameModel,
            beatInterval: beatMap.beatInterval,
            nextMiniGameType:
                beatMap.gameOrder[currentMiniGameIndex + 1].gameType,
          );
          break;
        case MiniGameType.tapTap:
          currentGameComponent = TapTapBoardComponent(
            model: nextMiniGameModel,
            beatInterval: beatMap.beatInterval,
          );
          break;
        case MiniGameType.tapTap4:
          currentGameComponent = TapTapBoardComponent(
            model: nextMiniGameModel,
            beatInterval: beatMap.beatInterval,
            numberOfColumns: 4,
          );
          break;
        case MiniGameType.tapTap7:
          currentGameComponent = TapTapLandscapeBoardComponent(
            model: nextMiniGameModel,
            beatInterval: beatMap.beatInterval,
          );
          break;
        case MiniGameType.osu:
          currentGameComponent = OsuGameComponent(
            model: nextMiniGameModel,
            beatInterval: beatMap.beatInterval,
          );
          break;
        case MiniGameType.tilt:
          currentGameComponent = TiltGameComponent(
            model: nextMiniGameModel,
            beatInterval: beatMap.beatInterval,
          );
          break;
        case MiniGameType.slide:
          currentGameComponent = SlideGameComponent(
            model: nextMiniGameModel,
            beatInterval: beatMap.beatInterval,
          );
          break;
        case MiniGameType.swipe:
          currentGameComponent = SwipeGameComponent(
            model: nextMiniGameModel,
            beatInterval: beatMap.beatInterval,
          );
          break;
        case MiniGameType.undertale:
          currentGameComponent = UndertaleGameComponent(
            model: nextMiniGameModel,
            beatInterval: beatMap.beatInterval,
          );
          break;
      }
      add(currentGameComponent);
    }
  }

  Future<void> _setupMusicAudio() async {
    await FlameAudio.audioCache.clearAll();
    await _audioPlayer.setAudioContext(
      AudioContext(
        android: AudioContextAndroid(
          usageType: AndroidUsageType.game,
        ),
      ),
    );
    await _audioPlayer.setSourceAsset(getLevelMP3PathMap(beatMap.level));
    await _audioPlayer.addAudioPositionListener((audioPosition) {
      if (_audioPlayer.hasAudioStarted && audioPosition > Duration.zero) {
        double expectedSongTime =
            microsecondsToSeconds(audioPosition.inMicroseconds);
        // If the levelTime has fallen out of alignment with the actual audio, reset it to the expected time.
        // This can happen from pausing/resuming, or from other audio delays.
        final audioOffset = expectedSongTime - songTime;
        if (audioOffset.abs() >= 0.1) {
          print(
              "Whoopsie! songTime was corrected. current songTime=$songTime : expectedSongTime=$expectedSongTime");
          levelTime += audioOffset;
        }
      }
    });
  }

  /// Execute a beat update for the game component.
  void handleBeat() {
    if (_currentLevelBeatCount <
        beatMap.beatTotal + GameTransitionComponent.TRANSITION_BEAT_COUNT) {
      if (levelState == LevelState.playingBeatMap) {
        backgroundComponent.beatUpdate();
      }
      // Handle each note that occurs during this beat.
      bool isLastBeatOfMiniGame = currentGameComponent.isLastBeat;
      currentGameComponent.handleUpcomingBeat(
        songBeatCount: _currentSongBeatCount,
      );
      // TODO should _currentLevelBeatCount be ++ or more calculated? Just in case multiple beats pass before the next update, you know?
      _currentLevelBeatCount++;
      // Check if if a new mini-game should be queued up for the next beat.
      if (isLastBeatOfMiniGame) {
        levelState = LevelState.playingBeatMap;
        scoreComponent.enableScoring();
        queueUpNextMiniGame();
      }
    }
    // If the song is finished, finish up remaining beats to allow notes to play out.
    else {
      _currentLevelBeatCount++;
    }
  }

  void _checkIfSongIsComplete() {
    if (levelState != LevelState.finished &&
        _currentSongBeatCount >
            beatMap.beatTotal + (INTERVAL_TIMING_MULTIPLIER * 2)) {
      levelState = LevelState.finished;
      scoreComponent.disableScoring();
      _audioPlayer.stop();
      gameRef.router.pushRoute(Route(
        () => SongLevelCompleteComponent(
          songBeatMap: beatMap,
          songScore: scoreComponent.songScore,
        ),
      ));
    }
  }

  void rotateLevel(DeviceOrientation orientation) {
    currentLevelOrientation = orientation;
    late Vector2 newGameSize;
    late double rotationAngle;
    if (orientation == DeviceOrientation.landscapeLeft) {
      rotationAngle = pi / 2;
      newGameSize = Vector2(game.size.y, game.size.x);
    } else if (orientation == DeviceOrientation.landscapeRight) {
      rotationAngle = -pi / 2;
      newGameSize = Vector2(game.size.y, game.size.x);
    } else {
      rotationAngle = 0.0;
      newGameSize = game.size;
    }
    // Rotate entire level component.
    angle = rotationAngle;
    // Resize/Rebuild any components that depend on the gameSize
    scoreComponent.resetWithGivenDimensions(newGameSize);
  }

  @override
  void update(double dt) {
    if (_audioPlayer.isReady) {
      if (levelState == LevelState.notStarted) {
        levelState = LevelState.loading;
        setGameComponents();
      } else if (levelState == LevelState.readyToStart) {
        // kick off the level at beat 0.
        levelState = LevelState.playingLevel;
        handleBeat();
      } else if (levelState == LevelState.playingLevel ||
          levelState == LevelState.playingBeatMap) {
        levelTime += dt;
        // Add time to timer. This timer is tied to the game clock, and will pause when the game clock does.
        _beatTimer.update(dt);
        // Start music if it hasn't started playing
        // We should make the call to play the audio BEFORE it actually should, due to the slight delay with the audio player.
        if (!_audioPlayer.hasAudioStarted &&
            songTime >=
                -microsecondsToSeconds(_audioPlayer.startDelayMicroseconds)) {
          print(
              "Audio starting at songTime=$songTime : Audio Delay=${microsecondsToSeconds(_audioPlayer.startDelayMicroseconds)}");
          _audioPlayer.start();
        }
      }
    }
    // The super.update call NEEDS to be at the end, so that the children are
    // working off the updated [songTime].
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    _checkIfSongIsComplete();
  }

  /// Stop the music!
  Future<void> pause() async {
    await _audioPlayer.pause();
  }

  /// Put that shit back on!
  Future<void> resume() async {
    if (_audioPlayer.hasAudioStarted) {
      await _audioPlayer.resume();
    }
  }

  @override
  void onRemove() {
    super.onRemove();
    _audioPlayer.dispose();
  }
}

enum LevelState {
  /// Nothing has happened yet.
  notStarted,

  /// Loading in level components.
  loading,

  /// Level is loaded and ready to start.
  readyToStart,

  /// Level has started playing (the first transition has been displayed)
  playingLevel,

  /// Level has started playing AND the beat map has started to execute (the first notes have started to appear).
  playingBeatMap,

  /// Level is finished and all minigames have completed.
  finished,
}
