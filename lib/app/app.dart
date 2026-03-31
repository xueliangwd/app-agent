import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import '../features/chat/data/chat_controller.dart';
import '../features/chat/presentation/chat_home_page.dart';

class AgentApp extends StatefulWidget {
  const AgentApp({super.key});

  @override
  State<AgentApp> createState() => _AgentAppState();
}

class _AgentAppState extends State<AgentApp> {
  late final ChatController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ChatController()..bootstrap();
  }

  @override
  void dispose() {
    _controller.dispose();
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
          home: ChatHomePage(controller: _controller),
        );
      },
    );
  }
}
