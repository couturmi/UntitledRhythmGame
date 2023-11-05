import 'dart:async';

import 'package:flame_audio/flame_audio.dart';

/// Get it? "ON" Beat? Because the audio isn't "Off"beat? Like the game is?
///
/// But actually, this audio player is used to fix the beat timing issues with the
/// generic [AudioPlayer].
class OnBeatAudioPlayer extends AudioPlayer {
  bool _hasAudioStarted = false;

  /// True once the audio has first started playing for the level. This does not represent if
  /// the audio is currently playing vs paused, but instead if the level has
  /// reached the point where the audio would've started playing.
  bool get hasAudioStarted => _hasAudioStarted;

  /// Subscription for the audio player position.
  late StreamSubscription _audioPlayerPositionSubscription;

  List<Duration> _prevPositions = [Duration.zero, Duration.zero];

  /// Duration that represents the offset that the audio position has incorrectly set itself.
  ///
  /// Explanation: There is a bug in the audio player that will start incrementing the position,
  /// then suddenly reset it, then increment from there, which creates an incorrect position
  /// (which varies between different devices). This value will store the estimated amount of time
  /// that was offset.
  Duration _lostDuration = Duration.zero;

  /// Calculated delay (in microseconds) that it takes the audio player to actually start
  /// playing music after calling [resume]. This is a calculated value because it is different
  /// for every device.
  ///
  /// This value will be "0" until [calibrate] is called to populate it.
  int startDelayMicroseconds = 0;

  Future<void> addAudioPositionListener(Function(Duration) listener) async {
    await _calibrate();
    _audioPlayerPositionSubscription =
        this.onPositionChanged.listen((Duration songPosition) {
      // Only execute this logic if the audio has actually started playing. We don't want this to occur during calibration or anything.
      if (hasAudioStarted) {
        // print('onPrevPositionChanged:${_prevPositions[0]}');
        // print('onPrevPositionChanged:${_prevPositions[1]}');
        // print('onPositionChanged:${songPosition.inMicroseconds}');

        // This condition should be impossible, but it happens. If this occurred, the audio position was reset and should be accounted for.
        // This is an annoying bug from AudioPlayers, being tracked here: https://github.com/bluefireteam/audioplayers/issues/1324
        // NOTE: I added the [_lostDuration == Duration.zero] condition because I only want this to happen to fix the weird bug.
        if (_prevPositions[1] > songPosition &&
            _lostDuration == Duration.zero) {
          // Determine the expected position of the song, and calculate how much time was lost
          // for the audio player timer.
          // Note: This is likely not the "exact" offset value, it is only the observed
          // offset value from the timing of the listener (which kicks off every 200ms or so).
          Duration expectedIntervalDuration =
              _prevPositions[1] - _prevPositions[0];
          Duration expectedPosition =
              _prevPositions[1] + expectedIntervalDuration;
          _lostDuration += expectedPosition - songPosition;
          print(
              "OnBeatAudioPlayer: Impossible condition occurred. Duration lost in song position = $_lostDuration");
        }

        // Execute parent functionality with the correct song position.
        Duration correctPosition = songPosition + _lostDuration;
        listener(correctPosition);

        // Update the last 2 stored previous positions
        _prevPositions.add(songPosition);
        _prevPositions.removeAt(0);
      }
    });
  }

  /// Most hacky thing to get the audio timing to work correctly. Essentially,
  /// there is usually a slight delay when playing an audio file for the first
  /// time. So my solution was to play the audio player at zero volume first,
  /// to calibrate it. Then it can be played again for much less delay.
  Future<void> _calibrate() async {
    print("Calibrating OnBeatAudioPlayer");
    final int numberOfCalibrationTrials = 3;
    final List<int> trialElapsedTimeResults = [];
    final Stopwatch stopwatch = Stopwatch();

    final currentVolume = this.volume;
    await setVolume(0);
    for (int i = 0; i < numberOfCalibrationTrials; i++) {
      final Completer discoverDelayCompleter = Completer();
      var tempSubscription;
      tempSubscription = this.onPositionChanged.listen((Duration songPosition) {
        if (songPosition > Duration.zero) {
          int delay =
              stopwatch.elapsedMicroseconds - songPosition.inMicroseconds;
          trialElapsedTimeResults.add(delay);
          print("Trial $i delay: $delay");
          discoverDelayCompleter.complete();
          stopwatch.stop();
          stopwatch.reset();
          tempSubscription.cancel();
        }
      });

      // Start stop watch & audio player, and wait for the audio delay to be calculated.
      stopwatch.start();
      await resume();
      await discoverDelayCompleter.future;
      // Reset audio player to start of file.
      await pause();
      await seek(Duration.zero);
    }
    await setVolume(currentVolume);

    final totalDelayTimeForAllTrials = trialElapsedTimeResults.fold(
        0, (previous, current) => previous + current);
    startDelayMicroseconds =
        (totalDelayTimeForAllTrials / trialElapsedTimeResults.length).round();

    print(
        "Calibrated OnBeatAudioPlayer. Audio start delay = $startDelayMicroseconds");
  }

  /// Used to play the audio when the level starts.
  void start() {
    resume();
    _hasAudioStarted = true;
  }

  @override
  Future<void> dispose() {
    stop();
    _audioPlayerPositionSubscription.cancel();
    return super.dispose();
  }
}
