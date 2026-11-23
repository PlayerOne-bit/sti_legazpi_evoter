import 'package:flutter/material.dart';
import '../anim.dart';
import '../../data/mock.dart';
import '../../theme.dart';
import '../candidate_avatar.dart';

class CandidateCard extends StatelessWidget {
  final Candidate candidate;
  final bool selectable;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onInfo;

  const CandidateCard({
    super.key,
    required this.candidate,
    this.selectable = false,
    this.selected = false,
    this.onTap,
    this.onInfo,
  });

  Widget _initials(Candidate c) => Container(
        color: c.color,
        alignment: Alignment.center,
        child: Text(c.initials,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 40,
                fontWeight: FontWeight.w800)),
      );

  Widget _portrait(Candidate c) {
    final url = c.imageUrl;
    if (url == null) return _initials(c);
    return Image.network(url,
        key: ValueKey(url),
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        loadingBuilder: (_, child, p) => p == null ? child : _initials(c),
        errorBuilder: (_, __, ___) => _initials(c));
  }

  @override
  Widget build(BuildContext context) {
    final c = candidate;
    return Pressable(
        child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? C.tint : C.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: selected ? C.blue : C.line, width: selected ? 2.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(13)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _portrait(c),
                    if (selectable && selected)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: C.blue,
                          child:
                              Icon(Icons.check, size: 18, color: Colors.white),
                        ),
                      ),
                    if (onInfo != null)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: InkWell(
                          onTap: onInfo,
                          customBorder: const CircleBorder(),
                          child: Padding(
                            padding: EdgeInsets.all(2),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: C.surface,
                              child: Icon(Icons.info_outline,
                                  size: 18, color: C.blue),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800)),
                  Text(c.partyList,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: C.muted, fontSize: 12)),
                  if (c.motto.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('“${c.motto}”',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            height: 1.3)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

void showCandidateSheet(BuildContext context, Candidate c) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: C.surface,
    isScrollControlled: true,
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CandidateAvatar(candidate: c, radius: 36),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(c.name,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                    Text(c.partyList, style: TextStyle(color: C.muted)),
                  ],
                ),
              ),
            ],
          ),
          if (c.motto.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('“${c.motto}”',
                style:
                    const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    ),
  );
}
