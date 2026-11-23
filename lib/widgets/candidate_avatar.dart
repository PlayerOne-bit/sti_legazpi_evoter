import 'package:flutter/material.dart';
import '../data/mock.dart';

class CandidateAvatar extends StatelessWidget {
  final Candidate candidate;
  final double radius;
  const CandidateAvatar({super.key, required this.candidate, this.radius = 24});

  @override
  Widget build(BuildContext context) {
    final c = candidate;
    final initials = Center(
      child: Text(c.initials,
          style: TextStyle(
              color: Colors.white,
              fontSize: radius * 0.7,
              fontWeight: FontWeight.w800)),
    );
    final url = c.imageUrl;
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(color: c.color, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? initials
          : Image.network(url,
              key: ValueKey(url),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => initials),
    );
  }
}
