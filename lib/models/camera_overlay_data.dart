class CameraOverlayData {
  const CameraOverlayData({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? accuracyMeters;

  String get formattedLatitude => _formatCoordinate(latitude, 'N', 'S');
  String get formattedLongitude => _formatCoordinate(longitude, 'E', 'W');

  String get formattedAccuracy {
    final accuracy = accuracyMeters;
    if (accuracy == null) return 'Unknown';
    return '${accuracy.toStringAsFixed(1)} m';
  }

  String get formattedTimestamp {
    final local = timestamp.toLocal();
    final date =
        '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}';
    return '$date $time ${local.timeZoneName}';
  }

  static String _formatCoordinate(
    double value,
    String positiveSuffix,
    String negativeSuffix,
  ) {
    final suffix = value >= 0 ? positiveSuffix : negativeSuffix;
    return '${value.abs().toStringAsFixed(6)}° $suffix';
  }
}
