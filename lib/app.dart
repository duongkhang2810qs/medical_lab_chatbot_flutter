import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/chat/presentation/pages/chat_screen.dart';

class BloodTestApp extends StatelessWidget {
  const BloodTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trợ lý Xét nghiệm',
      theme: AppTheme.light,
      home: const ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
