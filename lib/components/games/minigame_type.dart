import 'dart:math';

import 'package:flutter/services.dart';

enum MiniGameType {
  gameTransition,
  tapTap,
  osu,
}

MiniGameType miniGameTypeFromString(String name) {
  return MiniGameType.values
      .firstWhere((type) => type.toString().split(".").last == name);
}

String getMiniGameName(MiniGameType game) {
  switch (game) {
    case MiniGameType.tapTap:
      return "Tap Hero";
    case MiniGameType.osu:
      return "OSU!"; // Whack-A-Note?
    case MiniGameType.gameTransition:
      throw ArgumentError(
          "This is a transition, and not a true mini-game, and "
          "therefore has no reason to have an associated name",
          game.toString());
  }
}

DeviceOrientation getOrientationForMiniGame(MiniGameType game) {
  Random rand = Random();
  final vertical = DeviceOrientation.portraitUp;
  final horizontal = rand.nextBool()
      ? DeviceOrientation.landscapeLeft
      : DeviceOrientation.landscapeRight;

  switch (game) {
    case MiniGameType.tapTap:
      return vertical;
    case MiniGameType.osu:
      return horizontal;
    case MiniGameType.gameTransition:
      throw ArgumentError(
          "This is a transition, and not a true mini-game, and "
          "therefore has no reason to have a static orientation",
          game.toString());
  }
}
