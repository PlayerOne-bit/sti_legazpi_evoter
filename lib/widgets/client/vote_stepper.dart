import 'package:flutter/material.dart';
import '../../theme.dart';

class VoteStepper extends StatelessWidget {
  final List<String> labels;
  final int current;
  final bool Function(int) canGoTo;
  final ValueChanged<int> onTap;

  const VoteStepper({
    super.key,
    required this.labels,
    required this.current,
    required this.canGoTo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final last = labels.length - 1;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < labels.length; i++) ...[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: canGoTo(i) ? () => onTap(i) : null,
            child: SizedBox(
              width: 68,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < current ? C.blue : C.surface,
                      border: Border.all(
                        color: i <= current ? C.blue : C.line,
                        width: i == current ? 4 : 2,
                      ),
                    ),
                    child: i < current
                        ? const Icon(Icons.check, size: 18, color: Colors.white)
                        : (i == last && i != current
                            ? Icon(Icons.how_to_vote, size: 16, color: C.muted)
                            : null),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.2,
                      fontWeight:
                          i == current ? FontWeight.w800 : FontWeight.w500,
                      color: i <= current ? C.ink : C.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (i < last)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 14.5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 3,
                  decoration: BoxDecoration(
                    color: i < current ? C.blue : C.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
