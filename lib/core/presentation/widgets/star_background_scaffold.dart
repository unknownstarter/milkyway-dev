import 'package:flutter/material.dart';
import '../../../features/home/presentation/widgets/star_background_painter.dart';

class StarBackgroundScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final int numberOfStars;

  const StarBackgroundScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.numberOfStars = 150,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: appBar,
      body: Stack(
        children: [
          CustomPaint(
            painter: StarBackgroundPainter(numberOfStars: numberOfStars),
            child: const SizedBox.expand(),
          ),
          body,
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
