import 'dart:io';
import 'package:flutter/material.dart';
import '../data/api.dart';
import '../data/app_update.dart';
import '../theme.dart';

Future<void> showUpdateDialog(
    BuildContext context, AppUpdateInfo info, String currentVersion) async {
  var stage = _Stage.ready;
  var progress = 0.0;
  String? message;
  File? file;

  String mb(int bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => PopScope(
      canPop: !info.mandatory,
      child: StatefulBuilder(builder: (ctx, setS) {
        Future<void> run() async {
          setS(() {
            message = null;
            if (file == null) {
              stage = _Stage.downloading;
              progress = 0;
            }
          });
          try {
            file ??= await AppUpdater.download(info, (got, total) {
              if (total > 0) setS(() => progress = got / total);
            });
            setS(() => stage = _Stage.installing);
            await AppUpdater.install(file!);
            setS(() => stage = _Stage.waiting);
          } on InstallPermissionNeeded {
            setS(() {
              stage = _Stage.waiting;
              message =
                  'Allow STI eVoter to install apps in the screen that opened, then come back and tap Install.';
            });
          } on ApiException catch (e) {
            setS(() {
              stage = _Stage.ready;
              file = null;
              message = e.message;
            });
          } catch (_) {
            setS(() {
              stage = file == null ? _Stage.ready : _Stage.waiting;
              message = 'The update could not be completed. Please try again.';
            });
          }
        }

        final busy = stage == _Stage.downloading || stage == _Stage.installing;
        return AlertDialog(
          titlePadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [C.blue, C.blueDeep],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: C.yellow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.system_update_alt,
                      color: C.onYellow, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          info.mandatory
                              ? 'Update required'
                              : 'Update available',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 19,
                              fontWeight: FontWeight.w800)),
                      Text(
                          'Version ${info.version}  ·  you have $currentVersion',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (info.notes.trim().isNotEmpty) ...[
                  Text("What's new",
                      style: TextStyle(
                          color: C.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 160),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: C.surface2,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SingleChildScrollView(child: Text(info.notes)),
                  ),
                  const SizedBox(height: 12),
                ],
                if (info.mandatory)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                        'This version is no longer supported. Update to keep using the app.',
                        style: TextStyle(color: C.warnFg, fontSize: 13)),
                  ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: switch (stage) {
                    _Stage.ready => Text('Download size: ${mb(info.size)}',
                        key: const ValueKey('ready'),
                        style: TextStyle(color: C.muted, fontSize: 13)),
                    _Stage.downloading => Column(
                        key: const ValueKey('dl'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress == 0 ? null : progress,
                              minHeight: 8,
                              color: C.blue,
                              backgroundColor: C.tint,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                              'Downloading ${(progress * 100).round()}%  ·  ${mb((progress * info.size).round())} of ${mb(info.size)}',
                              style: TextStyle(color: C.muted, fontSize: 12.5)),
                        ],
                      ),
                    _Stage.installing => Row(
                        key: const ValueKey('inst'),
                        children: [
                          const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2)),
                          const SizedBox(width: 10),
                          Text(Platform.isWindows
                              ? 'Installing. The app will restart...'
                              : 'Opening the installer...'),
                        ],
                      ),
                    _Stage.waiting => Text(
                        'Tap Install in the system screen to finish. '
                        'If it closed, tap Install again.',
                        key: const ValueKey('wait'),
                        style: TextStyle(color: C.muted, fontSize: 13)),
                  },
                ),
                if (message != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(message!, style: TextStyle(color: C.danger)),
                  ),
              ],
            ),
          ),
          actions: [
            if (!info.mandatory)
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(ctx),
                child: const Text('Later'),
              ),
            FilledButton.icon(
              onPressed: busy ? null : run,
              icon: Icon(stage == _Stage.waiting
                  ? Icons.install_mobile
                  : Icons.download),
              label: Text(stage == _Stage.waiting
                  ? 'Install'
                  : busy
                      ? 'Please wait...'
                      : 'Update now'),
            ),
          ],
        );
      }),
    ),
  );
}

enum _Stage { ready, downloading, installing, waiting }
