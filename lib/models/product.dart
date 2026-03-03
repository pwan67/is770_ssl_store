class Product {
  final String id;
  final String name;
  final String description;
  final double price; // Base price or MSRP (if applicable)
  final double weight; // In Baht
  final double laborFee; // Cost of craftsmanship
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
    required this.stock,
    required this.imageUrl,
    required this.category,
  });

  Product copyWith({int? stock}) {
    return Product(
      id: id,
      name: name,
      description: description,
      price: price,
      weight: weight,
      laborFee: laborFee,
      stock: stock ?? this.stock,
      imageUrl: imageUrl,
      category: category,
    );
  }
}
