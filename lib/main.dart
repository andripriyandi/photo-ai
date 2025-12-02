import 'package:flutter/material.dart';
import 'package:photo_ai/app/config/app_config.dart';
import 'package:photo_ai/app/data/repositories/photo_session_repository_impl.dart';
import 'package:photo_ai/app/presentation/pages/photo_ai_page.dart';

void main() {
  AppConfig.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: Colors.blueAccent,
      scaffoldBackgroundColor: const Color(0xFF05060A),
    );

    final repository = PhotoSessionRepositoryImpl();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Photo AI Test",
      theme: theme,
      home: PhotoAiPage(repository: repository),
    );
  }
}
