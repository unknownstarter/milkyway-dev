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
        backgroundColor: Colors.black,
        actions: actions,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 