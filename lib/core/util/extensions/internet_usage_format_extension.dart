extension NeoInternetUsageFormatExtension on int {
  /// Format bytes in human readable format
  String get formattedBytesUsed {
    if (this < 1024) {
      return '${this}B';
    } else if (this < 1024 * 1024) {
      return '${(this / 1024).toStringAsFixed(1)}KB';
    } else if (this < 1024 * 1024 * 1024) {
      return '${(this / (1024 * 1024)).toStringAsFixed(1)}MB';
    } else {
      return '${(this / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
    }
  }
}
