class GoldRate {
  final double buyPrice;
  final double sellPrice;
  final DateTime timestamp; // Keep for internal tracking
  final String updateTime;  // API specific update time string, e.g. "16:50"
  final String trend; // 'up', 'down', 'stable'

  GoldRate({
    required this.buyPrice,
    required this.sellPrice,
    required this.timestamp,
    required this.updateTime,
    required this.trend,
  });
}
