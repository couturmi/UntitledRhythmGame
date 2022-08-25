import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:untitled_rhythm_game/my_game.dart';

main() {
  // Force portrait orientation before starting app.
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    // Run game.
    runApp(
      Padding(
        padding: const EdgeInsets.only(top: 16),
        child: GameWidget(
          game: MyGame(),
        ),
      ),
    );
  });
}