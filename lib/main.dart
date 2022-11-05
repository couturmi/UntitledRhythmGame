import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled_rhythm_game/my_game.dart';

main() {
  // Force portrait orientation before starting app.
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    // Run game.
    runApp(
      WidgetsApp(
        home: SafeArea(
        child: GameWidget(
          game: MyGame(),
        ),
      ),
        debugShowCheckedModeBanner: false,
        color: Colors.transparent,
        pageRouteBuilder: <T>(RouteSettings settings, WidgetBuilder builder) {
          return MaterialPageRoute<T>(settings: settings, builder: builder);
        },
      ),
    );
  });
}