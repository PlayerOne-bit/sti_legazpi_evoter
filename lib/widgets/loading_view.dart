import 'package:flutter/material.dart';
import '../theme.dart';
import 'blue_button.dart';

class LoadingView extends StatelessWidget {
  final String? error;
  final VoidCallback onRetry;
  const LoadingView({super.key, this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: error == null
            ? const CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off, color: C.muted, size: 40),
                    const SizedBox(height: 12),
                    Text(error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    SizedBox(
                        width: 200,
                        child:
                            BlueButton(label: 'Try again', onPressed: onRetry)),
                  ],
                ),
              ),
      );
}
