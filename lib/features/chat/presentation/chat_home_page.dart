import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/chat_controller.dart';
import '../data/settings_controller.dart';
import '../widgets/chat_detail_view.dart';
import '../widgets/chat_sidebar.dart';

class ChatHomePage extends StatelessWidget {
  const ChatHomePage({
    super.key,
    required this.controller,
    required this.settingsController,
  });

  final ChatController controller;
  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 980;

        if (isWide) {
          return Scaffold(
            body: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF6F2EA), Color(0xFFF3F7F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 320,
                        child: ChatSidebar(
                          controller: controller,
                          onOpenSession: controller.selectSession,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppTheme.panel,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: ChatDetailView(
                            controller: controller,
                            settingsController: settingsController,
                            sessionId: controller.selectedSessionId,
                            embedded: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF6F2EA),
          appBar: AppBar(title: const Text('App Agent')),
          body: ChatSidebar(
            controller: controller,
            onOpenSession: (sessionId) {
              controller.selectSession(sessionId);
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => ChatDetailView(
                    controller: controller,
                    settingsController: settingsController,
                    sessionId: sessionId,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
