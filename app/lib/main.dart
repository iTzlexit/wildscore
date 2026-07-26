import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/codex/codex_screen.dart';
import 'shared/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Locked to portrait. Phase 2 unlocks landscape for the camera only —
  // a collection app that reflows mid-scroll feels cheap.
  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const WildScoreApp());
}

class WildScoreApp extends StatelessWidget {
  const WildScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wild Score',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // Two screens, pushed with Navigator. go_router arrives in Phase 2 with
      // the bottom navigation bar and deep links into a shared sighting.
      home: const CodexScreen(),
    );
  }
}
