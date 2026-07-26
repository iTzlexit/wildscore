import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'features/app_root.dart';
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
      // AppRoot picks onboarding or the Codex depending on whether a tracker
      // profile exists on this device.
      home: const AppRoot(),
    );
  }
}
