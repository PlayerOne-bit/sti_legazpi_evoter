import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../theme.dart';

Future<Uint8List?> showSquareCropper(BuildContext context, Uint8List bytes) =>
    showDialog<Uint8List>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _CropDialog(bytes: bytes),
    );

class _CropDialog extends StatefulWidget {
  final Uint8List bytes;
  const _CropDialog({required this.bytes});

  @override
  State<_CropDialog> createState() => _CropDialogState();
}

class _CropDialogState extends State<_CropDialog> {
  static const double _box = 260;
  static const int _out = 512;

  final _key = GlobalKey();
  final _ctl = TransformationController();
  Size? _size;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final img = await decodeImageFromList(widget.bytes);
      final s = _box / (img.width < img.height ? img.width : img.height);
      final w = img.width * s, h = img.height * s;
      img.dispose();
      if (!mounted) return;
      setState(() {
        _size = Size(w, h);
        _ctl.value =
            Matrix4.translationValues(-(w - _box) / 2, -(h - _box) / 2, 0);
      });
    } catch (_) {
      if (mounted) setState(() => _error = 'That file is not a valid image.');
    }
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _busy = true);
    try {
      final boundary =
          _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: _out / _box);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (!mounted) return;
      Navigator.pop(context, data!.buffer.asUint8List());
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not crop the image. Try another one.';
        });
      }
    }
  }

  Widget _cropArea(Size? size) {
    if (_error != null) {
      return SizedBox(
        width: _box,
        child: Text(_error!, style: TextStyle(color: C.danger)),
      );
    }
    if (size == null) {
      return const SizedBox(
          width: _box,
          height: _box,
          child: Center(child: CircularProgressIndicator()));
    }
    return SizedBox(
      width: _box,
      height: _box,
      child: Stack(
        children: [
          RepaintBoundary(
            key: _key,
            child: ClipRect(
              child: InteractiveViewer(
                transformationController: _ctl,
                constrained: false,
                minScale: 1,
                maxScale: 6,
                boundaryMargin: EdgeInsets.zero,
                child: Image.memory(widget.bytes,
                    width: size.width,
                    height: size.height,
                    fit: BoxFit.fill,
                    gaplessPlayback: true),
              ),
            ),
          ),
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 2)),
              child: CustomPaint(painter: _GridPainter(), size: Size.infinite),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buttons(Size? size) => [
        TextButton(
            onPressed: _busy ? null : () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: (_busy || size == null) ? null : _confirm,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Confirm'),
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final size = _size;
    final hint = Text('Drag to move, pinch or scroll to zoom.',
        style: TextStyle(color: C.muted, fontSize: 13));

    // A phone held sideways is too short for the photo above the buttons, so put them side by side.
    if (MediaQuery.sizeOf(context).height < 520) {
      return Dialog(
        insetPadding: const EdgeInsets.all(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _cropArea(size),
              const SizedBox(width: 16),
              SizedBox(
                width: 230,
                height: _box,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Crop photo',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    hint,
                    const Spacer(),
                    Wrap(
                      alignment: WrapAlignment.end,
                      spacing: 8,
                      runSpacing: 8,
                      children: _buttons(size),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AlertDialog(
      insetPadding: const EdgeInsets.all(16),
      contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      title: const Text('Crop photo'),
      content: SizedBox(
        width: _box,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            hint,
            const SizedBox(height: 12),
            _cropArea(size),
            const SizedBox(height: 12),
          ],
        ),
      ),
      actions: _buttons(size),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = Colors.white54
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      canvas.drawLine(
          Offset(s.width * i / 3, 0), Offset(s.width * i / 3, s.height), p);
      canvas.drawLine(
          Offset(0, s.height * i / 3), Offset(s.width, s.height * i / 3), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
