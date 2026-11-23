import 'package:flutter/material.dart';
import '../../data/candidate_images.dart';
import '../../data/mock.dart';
import '../../theme.dart';

const partySwatches = <String>[
  '#0A4DA2',
  '#C62828',
  '#2E7D32',
  '#6A1B9A',
  '#EF6C00',
  '#00838F',
  '#AD1457',
  '#37474F',
  '#F9A825',
  '#4E342E',
];

Color? parseHex(String? hex) {
  if (hex == null || hex.length != 7 || !hex.startsWith('#')) return null;
  final v = int.tryParse(hex.substring(1), radix: 16);
  return v == null ? null : Color(0xFF000000 | v);
}

Color partyColor(int? id, String? hex) {
  final parsed = parseHex(hex);
  if (parsed != null) return parsed;
  if (id == null) return const Color(0xFF546E7A);
  return parseHex(partySwatches[id % partySwatches.length])!;
}

Color onColor(Color c) =>
    c.computeLuminance() > 0.5 ? const Color(0xFF16202E) : Colors.white;

Color darker(Color c, [double amount = 0.18]) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
}

class PartyLogo extends StatelessWidget {
  final String name;
  final String? logoUrl;
  final Color color;
  final double radius;
  final double ring;

  const PartyLogo({
    super.key,
    required this.name,
    required this.logoUrl,
    required this.color,
    required this.radius,
    this.ring = 0,
  });

  factory PartyLogo.of(PartyList p,
          {required double radius, double ring = 0}) =>
      PartyLogo(
          name: p.name,
          logoUrl: p.logoUrl,
          color: partyColor(p.id, p.color),
          radius: radius,
          ring: ring);

  @override
  Widget build(BuildContext context) {
    final words = name.trim().split(RegExp(r'\s+'));
    final initials = words.isEmpty || words.first.isEmpty
        ? '?'
        : (words.first[0] + (words.length > 1 ? words.last[0] : ''))
            .toUpperCase();
    final fallback = Container(
      color: color,
      alignment: Alignment.center,
      child: Text(initials,
          style: TextStyle(
              color: onColor(color),
              fontSize: radius * 0.75,
              fontWeight: FontWeight.w800)),
    );
    final url = logoUrl;
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: ring > 0 ? Border.all(color: Colors.white, width: ring) : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: url == null
          ? fallback
          : Image.network(url,
              key: ValueKey(url),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback),
    );
  }
}

Future<void> showPartyEditor(BuildContext context, int partyId) async {
  bool busy = false;
  String? error;
  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
      final p = state.partyLists.where((x) => x.id == partyId).firstOrNull;
      if (p == null) return const SizedBox.shrink();
      final color = partyColor(p.id, p.color);

      Future<void> run(Future<String?> Function() action) async {
        setS(() {
          busy = true;
          error = null;
        });
        final err = await action();
        if (err == null) await state.loadPartyLists();
        if (ctx.mounted) {
          setS(() {
            busy = false;
            error = err;
          });
        }
      }

      return AlertDialog(
        contentPadding: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, darker(color)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    PartyLogo.of(p, radius: 44, ring: 3),
                    const SizedBox(height: 12),
                    Text(p.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: onColor(color),
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Theme color',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final hex in partySwatches)
                          _Swatch(
                            color: parseHex(hex)!,
                            selected: color == parseHex(hex),
                            onTap: busy
                                ? null
                                : () =>
                                    run(() => state.setPartyColor(p.id, hex)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: busy
                                ? null
                                : () => run(() =>
                                    CandidateImages.pickAndUploadTo(ctx,
                                        '/api/admin/party-lists/${p.id}/logo')),
                            icon: const Icon(Icons.upload),
                            label: Text(p.logoUrl == null
                                ? 'Upload logo'
                                : 'Change logo'),
                          ),
                        ),
                        if (p.logoUrl != null) ...[
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: busy
                                ? null
                                : () => run(() => state.removePartyLogo(p.id)),
                            child: const Text('Remove'),
                          ),
                        ],
                      ],
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(error!, style: TextStyle(color: C.danger)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: busy ? null : () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      );
    }),
  );
}

class _Swatch extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback? onTap;
  const _Swatch({required this.color, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
              color: selected ? C.ink : Colors.transparent, width: 3),
          boxShadow: [
            if (selected)
              BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
          ],
        ),
        child: selected
            ? Icon(Icons.check, size: 18, color: onColor(color))
            : null,
      ),
    );
  }
}
