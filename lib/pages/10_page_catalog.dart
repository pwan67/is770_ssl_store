import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/gold_rate.dart';
import '../services/mock_service.dart';
import '../widgets/product_card.dart';
import '11_page_product_detail.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});

  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final MockService _service = MockService();
  late Stream<GoldRate> _goldRateStream;
  late Stream<List<Product>> _productsStream;
  GoldRate? _currentRate;
  
  String _searchQuery = '';
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Necklace', 'Ring', 'Bracelet', 'Earrings', 'Gold Bar'];

  @override
  void initState() {
    super.initState();
    _productsStream = _service.getProductsStream();
    
    _goldRateStream = _service.getGoldRateStream();
    _goldRateStream.listen((rate) {
      if (mounted) setState(() => _currentRate = rate);
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jewelry Store'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Catalog is connected to live Firestore!'))
               );
            },
            tooltip: 'Live Connection',
          )
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search jewelry...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          
          // Category Chips
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = category);
                    },
                    selectedColor: const Color(0xFF800000),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSelected ? const Color(0xFF800000) : Colors.grey[300]!,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Product Grid
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: _productsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                final allCloudProducts = snapshot.data ?? [];
                
                // Apply local filters (search query + category)
                final productsToShow = allCloudProducts.where((p) {
                  final matchesSearch = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
                  return matchesSearch && matchesCategory;
                }).toList();

                if (productsToShow.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('No jewelry found matching your criteria.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 16)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syncing products...')));
                              await MockService().seedDummyProducts();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Products synced successfully!')));
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                              }
                            }
                          },
                          icon: const Icon(Icons.sync),
                          label: const Text('Sync Dummy Products'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF800000),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: productsToShow.length,
                        itemBuilder: (context, index) {
                          return ProductCard(
                            product: productsToShow[index],
                            currentRate: _currentRate,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailPage(
                                    product: productsToShow[index],
                                    currentRate: _currentRate,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
              }
            ),
          ),
        ],
      ),
    );
  }
}
