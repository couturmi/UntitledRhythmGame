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
import 'package:untitled_rhythm_game/components/games/tilt/tilt_game_component.dart';
import 'package:untitled_rhythm_game/components/games/transition/minigame_transition_component.dart';
import 'package:untitled_rhythm_game/components/mixins/game_size_aware.dart';
import 'package:untitled_rhythm_game/components/scoring/score_component.dart';
import 'package:untitled_rhythm_game/level_constants.dart';
import 'package:untitled_rhythm_game/model/beat_map.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:untitled_rhythm_game/my_game.dart';
import 'package:untitled_rhythm_game/song_level_complete_component.dart';
import 'package:untitled_rhythm_game/util/time_utils.dart';

class SongLevelComponent extends PositionComponent
    with GameSizeAware, HasGameRef<MyGame> {
  /// Delay that the music should start at compared to when the notes are added. (TODO this is a temporary solution. This may be fixed with a more recent version of the audio player)
  static const int AUDIO_DELAY_MICROSECONDS =
      // 258000; // For the simulator.
      // 20000; // For my iPhone.
      150000; // For my Android phone.

  /// The number of beat intervals it should take a note from creation to reach the hit mark.
  /// TODO 2 = hard, 3 = medium, 4 = easy
  static const int INTERVAL_TIMING_MULTIPLIER = 2;

  final Level songLevel;

  /// Index of the current mini-game being played. Value is -1 when no games have started.
  late int currentMiniGameIndex = -1;

  /// Current beat count for the entire song.
  /// Note that this does NOT the represent the current beat playing in the audio, instead it is
  /// the current beat that is being loaded.
  int _currentBeatCount = 0;

  /// True once the level is loaded and ready to begin.
  bool hasLevelStarted = false;

  /// True once the level is finished and all minigames have completed.
  bool hasLevelFinished = false;

  /// True once the beat map has started to execute.
  bool hasSongStarted = false;

  /// True once the audio has first started playing. This does not represent if
  /// the audio is currently playing vs paused, but instead if the level has
  /// reached the point where the audio would've started playing.
  bool hasAudioStarted = false;

  /// Time (in seconds) from the start of the music playing.
  double songTime = 0.0;

  /// Current orientation that the level is set to.
  DeviceOrientation currentLevelOrientation = DeviceOrientation.portraitUp;

  late final BeatMap _beatMap;
  late AudioPlayer _audioPlayer;

  late final LevelBackgroundComponent backgroundComponent;
  late final ScoreComponent scoreComponent;
  late MiniGameComponent currentGameComponent;
  late MiniGameComponent previousGameComponent;

  SongLevelComponent({required this.songLevel});

  bool get hasNextBeatPassed =>
      (songTime / microsecondsToSeconds(_beatMap.beatInterval)) >
      _currentBeatCount;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Clear existing audio cache and preload song.
    FlameAudio.audioCache.clearAll();
    _setupMusicAudio();
    // Load song BeatMap.
    _beatMap = await BeatMap.loadFromFile(getLevelBeatMapPath(songLevel));
    // Set game components.
    setGameComponents();
  }

  void setGameComponents() {
    backgroundComponent = getLevelBackgroundComponent(
        level: songLevel, interval: _beatMap.beatInterval);
    scoreComponent = ScoreComponent();
    add(backgroundComponent);
    add(scoreComponent);
    setStartingTransition();
  }

  /// Set the starting MiniGame transition that introduces the first MiniGame.
  void setStartingTransition() {
    currentGameComponent = GameTransitionComponent(
      model: MiniGameModel.gameStartTransition(),
      beatInterval: _beatMap.beatInterval,
      nextMiniGameType: _beatMap.gameOrder[0].gameType,
      isStartingTransition: true,
    );
    add(currentGameComponent);
  }

  /// Queue up the next mini-game.
  void queueUpNextMiniGame() {
    // Set up the next mini-game as the current component.
    currentMiniGameIndex++;
    if (_beatMap.gameOrder.length > currentMiniGameIndex) {
      MiniGameModel nextMiniGameModel =
          _beatMap.gameOrder[currentMiniGameIndex];
      switch (nextMiniGameModel.gameType) {
        case MiniGameType.gameTransition:
          currentGameComponent = GameTransitionComponent(
            model: nextMiniGameModel,
            beatInterval: _beatMap.beatInterval,
            nextMiniGameType:
                _beatMap.gameOrder[currentMiniGameIndex + 1].gameType,
          );
          break;
        case MiniGameType.tapTap:
          currentGameComponent = TapTapBoardComponent(
            model: nextMiniGameModel,
            beatInterval: _beatMap.beatInterval,
          );
          break;
        case MiniGameType.osu:
          currentGameComponent = OsuGameComponent(
            model: nextMiniGameModel,
            beatInterval: _beatMap.beatInterval,
          );
          break;
        case MiniGameType.tilt:
          currentGameComponent = TiltGameComponent(
            model: nextMiniGameModel,
            beatInterval: _beatMap.beatInterval,
          );
          break;
        case MiniGameType.slide:
          currentGameComponent = SlideGameComponent(
            model: nextMiniGameModel,
            beatInterval: _beatMap.beatInterval,
          );
          break;
        case MiniGameType.swipe:
          currentGameComponent = SwipeGameComponent(
            model: nextMiniGameModel,
            beatInterval: _beatMap.beatInterval,
          );
          break;
      }
      add(currentGameComponent);
    }
  }

  void _setupMusicAudio() async {
    Uri audioFile = await FlameAudio.audioCache
        .fetchToMemory(getLevelMP3PathMap(songLevel));
    _audioPlayer = AudioPlayer(mode: PlayerMode.MEDIA_PLAYER);
    await _audioPlayer.setUrl(
      audioFile.toString(),
    );
  }

  /// Pause audio, and adjust the [songTime] to account for delay.
  ///
  /// Note: This shouldn't be necessary once the song delay issue is fixed,
  /// if we periodically check the song timing for corrections.
  Future<void> _pauseAudio() async {
    DateTime audioChangeStart = DateTime.now();
    await _audioPlayer.pause();
    DateTime audioChangeComplete = DateTime.now();
    songTime += microsecondsToSeconds(
            audioChangeComplete.difference(audioChangeStart).inMicroseconds) +
        0.004;
  }

  /// Resume audio, and adjust the [songTime] to account for delay.
  ///
  /// Note: This shouldn't be necessary once the song delay issue is fixed,
  /// if we periodically check the song timing for corrections.
  Future<void> _resumeAudio() async {
    DateTime audioChangeStart = DateTime.now();
    await _audioPlayer.resume();
    DateTime audioChangeComplete = DateTime.now();
    songTime += microsecondsToSeconds(
            audioChangeComplete.difference(audioChangeStart).inMicroseconds) +
        0.004;
  }

  /// Start the song notes.
  void _startSong() {
    // Reset beat count and song time to align with the actual song.
    songTime = 0;
    _currentBeatCount = 0;
    // Set flag that song notes have officially started.
    hasSongStarted = true;
  }

  /// Execute a beat update for the game component.
  void handleBeat() {
    if (_currentBeatCount < _beatMap.beatTotal) {
      if (hasSongStarted) {
        backgroundComponent.beatUpdate();
      }
      // Handle each note that occurs during this beat.
      bool isLastBeatOfMiniGame = currentGameComponent.isLastBeat;
      currentGameComponent.handleUpcomingBeat(songBeatCount: _currentBeatCount);
      // TODO should _currentBeatCount be ++ or more calculated? Just in case multiple beats pass before the next update, you know?
      _currentBeatCount++;
      // Check if if a new mini-game should be queued up for the next beat.
      if (isLastBeatOfMiniGame) {
        queueUpNextMiniGame();
        if (!hasSongStarted) {
          _startSong();
        }
      }
    }
    // If the song is finished, finish up remaining beats to allow notes to play out.
    else {
      _currentBeatCount++;
    }
  }

  void _checkIfSongIsComplete() {
    if (!hasLevelFinished &&
        _currentBeatCount >
            _beatMap.beatTotal + (INTERVAL_TIMING_MULTIPLIER * 2)) {
      hasLevelFinished = true;
      _audioPlayer.stop();
      gameRef.router.pushRoute(Route(
        () => SongLevelCompleteComponent(
          level: songLevel,
          songBeatMap: _beatMap,
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
  void update(double dt) {
    // First update occurs too late, so don't include it in the level progression.
    if (!hasLevelStarted) {
      hasLevelStarted = true;
    } else if (!hasLevelFinished) {
      songTime += dt;
      if (hasSongStarted) {
        // Start the audio if it hasn't been started yet.
        if (!hasAudioStarted &&
            ((songTime + microsecondsToSeconds(AUDIO_DELAY_MICROSECONDS)) /
                    microsecondsToSeconds(_beatMap.beatInterval)) >
                INTERVAL_TIMING_MULTIPLIER) {
          hasAudioStarted = true;
          _resumeAudio();
        }
      }
      // Handle the next beat if one has passed.
      if (hasNextBeatPassed) {
        handleBeat();
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
  void pause() {
    _pauseAudio();
  }

  /// Put that shit back on!
  void resume() {
    if (hasAudioStarted) {
      _resumeAudio();
    }
  }

  @override
  void onRemove() {
    super.onRemove();
    _audioPlayer.dispose();
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
