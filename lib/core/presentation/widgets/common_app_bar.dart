import 'package:flutter/material.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool centerTitle;
  const CommonAppBar({
    required this.title,
    this.actions,
    this.centerTitle = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) => AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        centerTitle: centerTitle,
        backgroundColor: const Color(0xFF181818),
        surfaceTintColor: Colors.transparent, // Material 3에서 스크롤 시 색상 변경 방지
        actions: actions,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 