class Product {
  final String id;
  final String name;
  final String description;
  final double price; // Base price or MSRP (if applicable)
  final double weight; // In Baht
  final double laborFee; // Cost of craftsmanship
  final double costBasis; // Weighted average acquisition cost
  final int stock; // Available quantity
  final String imageUrl;
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.weight,
    required this.laborFee,
    required this.costBasis,
    required this.stock,
    required this.imageUrl,
    required this.category,
  });

  Product copyWith({int? stock, double? costBasis}) {
    return Product(
      id: id,
      name: name,
      description: description,
      price: price,
      weight: weight,
      laborFee: laborFee,
      costBasis: costBasis ?? this.costBasis,
      stock: stock ?? this.stock,
      imageUrl: imageUrl,
      category: category,
    );
  }
}
