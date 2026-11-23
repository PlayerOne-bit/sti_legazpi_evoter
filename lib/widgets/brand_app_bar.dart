import 'package:flutter/material.dart';
import '../theme.dart';

class BrandAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showLogo;
  final bool themeToggle;

  const BrandAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.actions,
    this.showLogo = false,
    this.themeToggle = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8 + 3);

  @override
  Widget build(BuildContext context) {
    final fg = C.dark ? C.ink : Colors.white;
    final sub = C.dark ? C.muted : Colors.white70;
    return AppBar(
      toolbarHeight: kToolbarHeight + 8,
      titleSpacing: showLogo ? 12 : null,
      flexibleSpace: C.dark
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [C.blue, C.blueDeep],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
      title: Row(
        children: [
          if (showLogo) ...[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: C.yellow, width: 2),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/logo.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.how_to_vote, color: C.blue, size: 22)),
            ),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  DefaultTextStyle.merge(
                    style: TextStyle(
                        color: fg, fontSize: 19, fontWeight: FontWeight.w800),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: title!,
                  ),
                if (subtitle != null)
                  Text(subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: sub,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        ...?actions,
        if (themeToggle) ThemeToggleButton(color: fg),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3),
        child: Container(height: 3, color: C.yellow),
      ),
    );
  }
}
