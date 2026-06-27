import 'package:flutter/material.dart';
import 'package:gps_camera/models/camera_overlay_data.dart';
import 'package:gps_camera/painters/camera_overlay_painter.dart';

class CameraOverlay extends StatelessWidget {
  const CameraOverlay({
    required this.overlayDataStream,
    super.key,
  });

  final Stream<CameraOverlayData> overlayDataStream;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: StreamBuilder<CameraOverlayData>(
          stream: overlayDataStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _PositionedOverlayPanel(
                child: _OverlayPanel(
                  child: _OverlayStatus(
                    icon: Icons.location_off,
                    text: _locationErrorMessage(snapshot.error),
                  ),
                ),
              );
            }

            final data = snapshot.data;
            if (data == null) {
              return const _PositionedOverlayPanel(
                child: _OverlayPanel(
                  child: _OverlayStatus(
                    icon: Icons.my_location,
                    text: 'Getting GPS location...',
                  ),
                ),
              );
            }

            return CustomPaint(
              painter: CameraOverlayPainter(
                data: data,
                style: CameraOverlayPaintStyle.forScale(1),
              ),
            );
          },
        ),
      ),
    );
  }

  String _locationErrorMessage(Object? error) {
    final message = error.toString();
    if (message.contains('disabled')) {
      return 'Location services are disabled.';
    }
    if (message.contains('denied')) {
      return 'Location permission is required.';
    }
    return 'GPS location is unavailable.';
  }
}

class _PositionedOverlayPanel extends StatelessWidget {
  const _PositionedOverlayPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 16,
          right: 16,
          bottom: 80,
          child: child,
        ),
      ],
    );
  }
}

class _OverlayPanel extends StatelessWidget {
  const _OverlayPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white),
        child: child,
      ),
    );
  }
}

class _OverlayStatus extends StatelessWidget {
  const _OverlayStatus({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
