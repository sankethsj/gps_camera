import 'package:flutter/material.dart';
import 'package:gps_camera/models/camera_overlay_data.dart';

class CameraOverlayLayout {
  const CameraOverlayLayout({
    required this.panelRect,
    required this.panelHeight,
  });

  final Rect panelRect;
  final double panelHeight;
}

class CameraOverlayPaintStyle {
  const CameraOverlayPaintStyle({
    required this.margin,
    required this.bottomOffset,
    required this.padding,
    required this.borderRadius,
    required this.iconSize,
    required this.iconGap,
    required this.labelWidth,
    required this.rowGap,
    required this.panelColor,
    required this.iconColor,
    required this.labelColor,
    required this.valueColor,
    required this.labelFontSize,
    required this.valueFontSize,
  });

  factory CameraOverlayPaintStyle.forScale(double scale) {
    return CameraOverlayPaintStyle(
      margin: 16 * scale,
      bottomOffset: 80 * scale,
      padding: 12 * scale,
      borderRadius: 8 * scale,
      iconSize: 18 * scale,
      iconGap: 8 * scale,
      labelWidth: 78 * scale,
      rowGap: 8 * scale,
      panelColor: Colors.black.withValues(alpha: 0.64),
      iconColor: Colors.white,
      labelColor: Colors.white70,
      valueColor: Colors.white,
      labelFontSize: 12 * scale,
      valueFontSize: 13 * scale,
    );
  }

  final double margin;
  final double bottomOffset;
  final double padding;
  final double borderRadius;
  final double iconSize;
  final double iconGap;
  final double labelWidth;
  final double rowGap;
  final Color panelColor;
  final Color iconColor;
  final Color labelColor;
  final Color valueColor;
  final double labelFontSize;
  final double valueFontSize;
}

class CameraOverlayPainter extends CustomPainter {
  CameraOverlayPainter({
    required this.data,
    required this.style,
  });

  final CameraOverlayData data;
  final CameraOverlayPaintStyle style;

  static CameraOverlayLayout layoutFor({
    required Size size,
    required CameraOverlayData data,
    required CameraOverlayPaintStyle style,
  }) {
    final rowHeight = _measureRowHeight(style);
    final panelHeight = style.padding * 2 + rowHeight * 4 + style.rowGap * 3;
    final panelRect = Rect.fromLTWH(
      style.margin,
      size.height - style.bottomOffset - panelHeight,
      size.width - style.margin * 2,
      panelHeight,
    );

    return CameraOverlayLayout(
      panelRect: panelRect,
      panelHeight: panelHeight,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    paintOverlay(
      canvas: canvas,
      size: size,
      data: data,
      style: style,
    );
  }

  static void paintOverlay({
    required Canvas canvas,
    required Size size,
    required CameraOverlayData data,
    required CameraOverlayPaintStyle style,
  }) {
    final layout = layoutFor(size: size, data: data, style: style);
    final panelRect = layout.panelRect;
    final panelRRect = RRect.fromRectAndRadius(
      panelRect,
      Radius.circular(style.borderRadius),
    );

    canvas.drawRRect(panelRRect, Paint()..color = style.panelColor);

    var y = panelRect.top + style.padding;
    for (final row in _rows(data)) {
      _paintRow(
        canvas: canvas,
        row: row,
        origin: Offset(panelRect.left + style.padding, y),
        width: panelRect.width - style.padding * 2,
        style: style,
      );
      y += _measureRowHeight(style) + style.rowGap;
    }
  }

  @override
  bool shouldRepaint(covariant CameraOverlayPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.style != style;
  }

  static List<_CameraOverlayRowData> _rows(CameraOverlayData data) {
    return [
      _CameraOverlayRowData(
        icon: Icons.location_on,
        label: 'Latitude',
        value: data.formattedLatitude,
      ),
      _CameraOverlayRowData(
        icon: Icons.explore,
        label: 'Longitude',
        value: data.formattedLongitude,
      ),
      _CameraOverlayRowData(
        icon: Icons.gps_fixed,
        label: 'Accuracy',
        value: data.formattedAccuracy,
      ),
      _CameraOverlayRowData(
        icon: Icons.schedule,
        label: 'Captured',
        value: data.formattedTimestamp,
      ),
    ];
  }

  static double _measureRowHeight(CameraOverlayPaintStyle style) {
    return style.iconSize;
  }

  static void _paintRow({
    required Canvas canvas,
    required _CameraOverlayRowData row,
    required Offset origin,
    required double width,
    required CameraOverlayPaintStyle style,
  }) {
    _paintIcon(
      canvas: canvas,
      icon: row.icon,
      offset: origin,
      style: style,
    );

    final labelLeft = origin.dx + style.iconSize + style.iconGap;
    _paintText(
      canvas: canvas,
      text: row.label,
      offset: Offset(labelLeft, origin.dy + 1 * style.iconSize / 18),
      width: style.labelWidth,
      color: style.labelColor,
      fontSize: style.labelFontSize,
      fontWeight: FontWeight.normal,
      textAlign: TextAlign.left,
    );

    final valueLeft = labelLeft + style.labelWidth;
    final valueWidth = width - style.iconSize - style.iconGap - style.labelWidth;
    _paintText(
      canvas: canvas,
      text: row.value,
      offset: Offset(valueLeft, origin.dy + 0.5 * style.iconSize / 18),
      width: valueWidth,
      color: style.valueColor,
      fontSize: style.valueFontSize,
      fontWeight: FontWeight.w600,
      textAlign: TextAlign.right,
    );
  }

  static void _paintIcon({
    required Canvas canvas,
    required IconData icon,
    required Offset offset,
    required CameraOverlayPaintStyle style,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          color: style.iconColor,
          fontSize: style.iconSize,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(minWidth: style.iconSize);

    textPainter.paint(canvas, offset);
  }

  static void _paintText({
    required Canvas canvas,
    required String text,
    required Offset offset,
    required double width,
    required Color color,
    required double fontSize,
    required FontWeight fontWeight,
    required TextAlign textAlign,
  }) {
    final textPainter = TextPainter(
      maxLines: 1,
      ellipsis: '...',
      textAlign: textAlign,
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);

    textPainter.paint(canvas, offset);
  }
}

class _CameraOverlayRowData {
  const _CameraOverlayRowData({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;
}
