class GoldRate {
  final double buyPrice;
  final double sellPrice;
  final DateTime timestamp; // Keep for internal tracking

  GoldRate({
    required this.buyPrice,
    required this.sellPrice,
    required this.timestamp,
  });
}
