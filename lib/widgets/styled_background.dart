import 'package:flutter/material.dart';

class StyledBackground extends StatelessWidget {
  final Widget child;

  const StyledBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A0A0A),
            Color(0xFF1A1A1A),
            Color(0xFF0F0F0F),
          ],
        ),
      ),
      child: child,
    );
  }
}
