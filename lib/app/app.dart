import 'package:flutter/material.dart';

import '../hub/home_screen.dart';
import 'theme/theme.dart';

class AllwaysGamesApp extends StatelessWidget {
  const AllwaysGamesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Allways Games',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeScreen(),
    );
  }
}
