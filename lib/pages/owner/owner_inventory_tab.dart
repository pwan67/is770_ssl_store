import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OwnerInventoryTab extends StatelessWidget {
  const OwnerInventoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16.0),
          width: double.infinity,
          color: Colors.white,
          child: const Text(
            'Inventory Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF800000)),
          ),
        ),
        Expanded(
          child: _buildInventoryList(),
        ),
      ],
    );
  }

  Widget _buildInventoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').orderBy('name').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No products found in inventory.'));
        }

        final formatter = NumberFormat('#,##0.00');

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'] as String? ?? 'Unknown Product';
            final stock = (data['stock'] as num?)?.toInt() ?? 0;
            final inStock = data['inStock'] as bool? ?? true;
            final priceOffset = (data['priceOffset'] as num?)?.toDouble() ?? 0.0;
            final weight = (data['weight'] as num?)?.toDouble() ?? 1.0;

            final isOutOfStock = stock <= 0 || !inStock;

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Weight: ${weight.toStringAsFixed(2)} Baht | Price Offset: ฿${formatter.format(priceOffset)}',
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isOutOfStock ? Colors.red[100] : Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isOutOfStock ? 'OUT OF STOCK' : 'Stock: $stock',
                                  style: TextStyle(
                                    color: isOutOfStock ? Colors.red[900] : Colors.green[900],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Color(0xFF1E88E5)),
                          tooltip: 'Add Stock (+1)',
                          onPressed: () {
                            doc.reference.update({
                              'stock': FieldValue.increment(1),
                              'inStock': true,
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.grey),
                          tooltip: 'Edit (Not implemented)',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Edit product details coming soon.')),
                            );
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
