import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../glass_button.dart';
import '../glass_card.dart';
import 'calibration_status_card.dart';

class CameraCalibrationView extends StatefulWidget {
  const CameraCalibrationView({
    required this.cameraController,
    required this.isInitializing,
    required this.error,
    required this.onRetryCamera,
    required this.onStartTrip,
    super.key,
  });

  final CameraController? cameraController;
  final bool isInitializing;
  final String? error;
  final VoidCallback onRetryCamera;
  final VoidCallback onStartTrip;

  @override
  State<CameraCalibrationView> createState() => _CameraCalibrationViewState();
}

class _CameraCalibrationViewState extends State<CameraCalibrationView> {
  bool _calibrationComplete = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor =
        isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText;
    final secondaryTextColor =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;
    final controller = widget.cameraController;
    final isReady = controller != null && controller.value.isInitialized;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Position Your Camera',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Ensure your face is clearly visible for accurate monitoring.',
                style: TextStyle(color: secondaryTextColor, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Camera Preview
              AspectRatio(
                aspectRatio: 4 / 3,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    color: Colors.black,
                    child: isReady
                        ? CameraPreview(controller)
                        : Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  widget.isInitializing
                                      ? const CircularProgressIndicator()
                                      : const Icon(
                                          Icons.videocam_off_rounded,
                                          color: Colors.white24,
                                          size: 48,
                                        ),
                                  const SizedBox(height: 14),
                                  Text(
                                    widget.isInitializing
                                        ? 'Initializing Camera...'
                                        : widget.error ?? 'Camera Unavailable',
                                    style: TextStyle(
                                      color: secondaryTextColor,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  if (!widget.isInitializing &&
                                      widget.error != null) ...[
                                    const SizedBox(height: 12),
                                    TextButton.icon(
                                      onPressed: widget.onRetryCamera,
                                      icon: const Icon(Icons.refresh_rounded),
                                      label: const Text('Retry'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Calibration Checklist Card
              CalibrationStatusCard(
                onComplete: () {
                  if (mounted) {
                    setState(() {
                      _calibrationComplete = true;
                    });
                  }
                },
              ),
              const SizedBox(height: 14),

              // Instructions Card
              GlassCard(
                padding: const EdgeInsets.all(16),
                borderRadius: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calibration Guide',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _guideRow(
                      Icons.phone_android_rounded,
                      'Place device at eye level',
                    ),
                    _guideRow(
                      Icons.wb_sunny_outlined,
                      'Avoid direct sunlight background',
                    ),
                    _guideRow(
                      Icons.face_retouching_natural_rounded,
                      'Keep entire face visible',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Bottom Button
              GlassButton(
                label: 'Start Trip',
                icon: Icons.play_arrow_rounded,
                color: _calibrationComplete
                    ? AppColors.safe
                    : (isDark ? Colors.white24 : Colors.black26),
                onPressed: _calibrationComplete
                    ? widget.onStartTrip
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please wait for camera calibration checks to complete...',
                            ),
                          ),
                        );
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _guideRow(IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor =
        isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.info, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: secondaryTextColor),
            ),
          ),
        ],
      ),
    );
  }
}
