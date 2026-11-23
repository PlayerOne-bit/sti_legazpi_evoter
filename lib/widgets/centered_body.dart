import 'package:flutter/material.dart';

class CenteredBody extends StatelessWidget {
  final double maxWidth;
  final Widget child;
  const CenteredBody({super.key, this.maxWidth = 1000, required this.child});

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        heightFactor: 1.0,
        child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth), child: child),
      );
}
