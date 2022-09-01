import 'dart:math';

import 'package:flutter/services.dart';

enum MiniGameType {
  gameTransition,
  tapTap,
  osu,
  tilt,
  slide,
  swipe,
}

MiniGameType miniGameTypeFromString(String name) {
  return MiniGameType.values.firstWhere((type) => type.name == name);
}

String getMiniGameName(MiniGameType game) {
  switch (game) {
    case MiniGameType.tapTap:
      return "Tap Hero";
    case MiniGameType.osu:
      return "OSU!"; // Whack-A-Note?
    case MiniGameType.tilt:
      return "↶Tilt↷";
    case MiniGameType.slide:
      return "←Drag→";
    case MiniGameType.swipe:
      return "←Dodge→";
    case MiniGameType.gameTransition:
      throw ArgumentError(
          "This is a transition, and not a true mini-game, and "
          "therefore has no reason to have an associated name",
          game.toString());
  }
}

DeviceOrientation getOrientationForMiniGame(MiniGameType game) {
  switch (game) {
    case MiniGameType.tapTap:
    case MiniGameType.tilt:
    case MiniGameType.swipe:
      return DeviceOrientation.portraitUp;
    case MiniGameType.osu:
    case MiniGameType.slide:
      Random rand = Random();
      return rand.nextBool()
          ? DeviceOrientation.landscapeLeft
          : DeviceOrientation.landscapeRight;
    case MiniGameType.gameTransition:
      throw ArgumentError(
          "This is a transition, and not a true mini-game, and "
          "therefore has no reason to have a static orientation",
          game.toString());
  }
}
