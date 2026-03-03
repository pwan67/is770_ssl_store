class GoldAsset {
  final String id;
  final String name;
  final double weight; // in Baht
  final String category;
  final DateTime acquisitionDate;
  final double acquisitionPrice;
  final String status; // 'owned', 'sold', 'pawned'

  GoldAsset({
    required this.id,
    required this.name,
    required this.weight,
    required this.category,
    required this.acquisitionDate,
    required this.acquisitionPrice,
    this.status = 'owned',
  });

  GoldAsset copyWith({String? status}) {
    return GoldAsset(
      id: id,
      name: name,
      weight: weight,
      category: category,
      acquisitionDate: acquisitionDate,
      acquisitionPrice: acquisitionPrice,
      status: status ?? this.status,
    );
  }
}
