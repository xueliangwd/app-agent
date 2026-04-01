import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/chat/data/chat_controller.dart';
import '../features/chat/data/settings_controller.dart';
import '../features/chat/presentation/chat_home_page.dart';

class AgentApp extends StatefulWidget {
  const AgentApp({super.key});

  @override
  State<AgentApp> createState() => _AgentAppState();
}

class _AgentAppState extends State<AgentApp> {
  late final ChatController _controller;
  late final SettingsController _settingsController;

  @override
  void initState() {
    super.initState();
    _settingsController = SettingsController();
    _settingsController.bootstrap();
    _controller = ChatController(settingsController: _settingsController)..bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
    _settingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'App Agent',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: ChatHomePage(
            controller: _controller,
            settingsController: _settingsController,
          ),
        );
      },
    );
  }
}
