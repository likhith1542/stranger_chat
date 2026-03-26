// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/message_model.dart';
import 'models/user_model.dart';
import 'providers/app_providers.dart';
import 'screens/splash_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // System UI
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: AppTheme.bg,
  ));

  // Hive
  await Hive.initFlutter();
  Hive.registerAdapter(UserModelAdapter());
  Hive.registerAdapter(ConnectionStatusAdapter());
  Hive.registerAdapter(MessageModelAdapter());
  Hive.registerAdapter(MessageStatusAdapter());
  Hive.registerAdapter(MessageTypeAdapter());

  // Storage
  final container = ProviderContainer();
  await container.read(storageProvider).initialize();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const StrangerApp(),
    ),
  );
}

class StrangerApp extends StatelessWidget {
  const StrangerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STRANGER',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}
