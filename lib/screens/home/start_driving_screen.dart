import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../widgets/glass_button.dart';
import '../../widgets/glass_card.dart';

class StartDrivingScreen extends StatefulWidget {
  const StartDrivingScreen({super.key});

  @override
  State<StartDrivingScreen> createState() => _StartDrivingScreenState();
}

class _StartDrivingScreenState extends State<StartDrivingScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isInitializingCamera = false;
  String? _cameraError;

  bool get _isCameraReady =>
      _cameraController != null && _cameraController!.value.isInitialized;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _cameraController = null;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    if (_isInitializingCamera) {
      return;
    }

    setState(() {
      _isInitializingCamera = true;
      _cameraError = null;
    });

    CameraController? controller;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) {
          return;
        }
        setState(() => _cameraError = 'No camera was found on this device.');
        return;
      }

      final selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _cameraController?.dispose();
      await controller.initialize();

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() => _cameraController = controller);
    } on CameraException catch (error) {
      await controller?.dispose();
      if (!mounted) {
        return;
      }
      setState(() => _cameraError = _cameraMessageFor(error));
    } catch (_) {
      await controller?.dispose();
      if (!mounted) {
        return;
      }
      setState(() => _cameraError = 'Unable to start the camera.');
    } finally {
      if (mounted) {
        setState(() => _isInitializingCamera = false);
      }
    }
  }

  String _cameraMessageFor(CameraException error) {
    return switch (error.code) {
      'CameraAccessDenied' ||
      'CameraAccessDeniedWithoutPrompt' ||
      'CameraAccessRestricted' =>
        'Camera permission is required to monitor drowsiness.',
      'AudioAccessDenied' => 'Camera started without microphone access.',
      _ => error.description ?? 'Unable to start the camera.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final status = _cameraStatus;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 118),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Start Driving',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Monitor driver alertness in real time.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.color?.withValues(alpha: 0.68),
                    ),
                  ),
                  const SizedBox(height: 22),
                  GlassCard(
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: status.color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(status.icon, color: status.color),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            status.label,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: status.color),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Driver Monitoring',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 18),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 620;
                            return CustomPaint(
                              painter: _DashedBorderPainter(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              child: AspectRatio(
                                aspectRatio: isWide ? 16 / 9 : 3 / 4,
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: _CameraPreviewPanel(
                                    controller: _cameraController,
                                    isInitializing: _isInitializingCamera,
                                    error: _cameraError,
                                    onRetry: _initializeCamera,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 680;
                      final cards = const [
                        _StatCard(
                          label: 'Blink Count',
                          value: '0',
                          icon: Icons.remove_red_eye_outlined,
                        ),
                        _StatCard(
                          label: 'Yawns',
                          value: '0',
                          icon: Icons.sentiment_dissatisfied_outlined,
                        ),
                        _StatCard(
                          label: 'Drowsiness Score',
                          value: '0%',
                          icon: Icons.speed_outlined,
                        ),
                      ];
                      if (!isWide) {
                        return Column(
                          children: [
                            for (final card in cards) ...[
                              card,
                              const SizedBox(height: 12),
                            ],
                          ],
                        );
                      }
                      return Row(
                        children: [
                          for (final card in cards)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: card,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  GlassButton(
                    label: _isCameraReady
                        ? 'Restart Camera'
                        : 'Start Monitoring',
                    icon: Icons.play_arrow_rounded,
                    color: AppColors.safe,
                    onPressed: _initializeCamera,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  _CameraStatus get _cameraStatus {
    if (_isInitializingCamera) {
      return const _CameraStatus(
        label: 'Status: Requesting Camera',
        color: AppColors.info,
        icon: Icons.sync,
      );
    }
    if (_cameraError != null) {
      return const _CameraStatus(
        label: 'Status: Camera Permission Required',
        color: AppColors.warning,
        icon: Icons.warning_amber_rounded,
      );
    }
    if (_isCameraReady) {
      return const _CameraStatus(
        label: 'Status: Camera Ready',
        color: AppColors.safe,
        icon: Icons.check_circle_outline,
      );
    }
    return const _CameraStatus(
      label: 'Status: Waiting for Camera',
      color: AppColors.info,
      icon: Icons.info_outline,
    );
  }
}

class _CameraPreviewPanel extends StatelessWidget {
  const _CameraPreviewPanel({
    required this.controller,
    required this.isInitializing,
    required this.error,
    required this.onRetry,
  });

  final CameraController? controller;
  final bool isInitializing;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final activeController = controller;
    final isReady =
        activeController != null && activeController.value.isInitialized;

    if (isReady) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ColoredBox(
          color: Colors.black,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final previewSize = activeController.value.previewSize;
              final fallbackAspectRatio = activeController.value.aspectRatio;
              final previewWidth = previewSize?.height ?? constraints.maxWidth;
              final previewHeight =
                  previewSize?.width ??
                  constraints.maxWidth / fallbackAspectRatio;

              return Center(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: previewWidth,
                    height: previewHeight,
                    child: CameraPreview(activeController),
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.08),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: isInitializing
                  ? const _CameraMessage(
                      key: ValueKey('loading-camera'),
                      icon: Icons.videocam_outlined,
                      message: 'Requesting camera access...',
                      showLoader: true,
                    )
                  : error != null
                  ? _CameraMessage(
                      key: const ValueKey('camera-error'),
                      icon: Icons.no_photography_outlined,
                      message: error!,
                      actionLabel: 'Try Again',
                      onAction: onRetry,
                    )
                  : _CameraMessage(
                      key: const ValueKey('camera-idle'),
                      icon: Icons.videocam_outlined,
                      message: 'Tap Start Monitoring to open camera',
                      actionLabel: 'Open Camera',
                      onAction: onRetry,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraMessage extends StatelessWidget {
  const _CameraMessage({
    required this.icon,
    required this.message,
    super.key,
    this.showLoader = false,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final bool showLoader;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 44, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (showLoader) ...[
          const SizedBox(height: 16),
          const SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onAction,
            icon: const Icon(Icons.refresh),
            label: Text(actionLabel!),
          ),
        ],
      ],
    );
  }
}

class _CameraStatus {
  const _CameraStatus({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    const dashWidth = 10.0;
    const dashGap = 7.0;
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(24),
    );
    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + dashWidth),
          paint,
        );
        distance += dashWidth + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
