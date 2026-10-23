import 'package:flutter/material.dart';
import '../../data/mock.dart';
import '../../theme.dart';

class CandidateCard extends StatefulWidget {
  final Candidate candidate;
  final bool selectable;
  final bool selected;
  final VoidCallback? onTap;

  const CandidateCard({
    super.key,
    required this.candidate,
    this.selectable = false,
    this.selected = false,
    this.onTap,
  });

  @override
  State<CandidateCard> createState() => _CandidateCardState();
}

class _CandidateCardState extends State<CandidateCard> {
  bool open = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.candidate;
    final sel = widget.selected;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: widget.selectable ? widget.onTap : () => setState(() => open = !open),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFFEAF1FB) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: sel ? C.blue : C.line, width: sel ? 2 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: c.color,
                    child: Text(c.initials,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(c.partyList, style: const TextStyle(color: C.muted)),
                      ],
                    ),
                  ),
                  if (widget.selectable)
                    Icon(sel ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: sel ? C.blue : C.line, size: 28)
                  else
                    Icon(open ? Icons.expand_less : Icons.expand_more, color: C.muted),
                ],
              ),
              if (!widget.selectable && open) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: C.line),
                const SizedBox(height: 12),
                Text(c.vision, style: const TextStyle(height: 1.5)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
