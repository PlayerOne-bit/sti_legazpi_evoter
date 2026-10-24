import 'package:flutter/material.dart';
import '../theme.dart';

class BlueButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;

  const BlueButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
        Flexible(child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700))),
      ],
    );
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
    const size = Size.fromHeight(52);
    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: size,
          shape: shape,
          foregroundColor: C.blue,
          side: const BorderSide(color: C.blue, width: 1.5),
        ),
        child: child,
      );
    }
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: size,
        shape: shape,
        backgroundColor: C.blue,
        foregroundColor: Colors.white,
        disabledBackgroundColor: C.line,
      ),
      child: child,
    );
  }
}
