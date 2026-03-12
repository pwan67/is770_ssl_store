import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OwnerInventoryCostPage extends StatelessWidget {
  const OwnerInventoryCostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory Cost Breakdown')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('market')
            .doc('gold_rate')
            .snapshots(),
        builder: (context, rateSnap) {
          final marketRate = (rateSnap.data?.data() as Map<String, dynamic>?)?['sellPrice']?.toDouble() ?? 42000.0;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('products').snapshots(),
            builder: (context, productSnap) {
              if (productSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final products = productSnap.data?.docs ?? [];
              if (products.isEmpty) {
                return const Center(child: Text('No products found.'));
              }

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('transactions')
                    .where('type', isEqualTo: 'restock')
                    .snapshots(),
                builder: (context, restockSnap) {
                  final restockDocs = restockSnap.data?.docs ?? [];
                  
                  // Aggregate Restock Costs
                  final Map<String, double> totalInvestedMap = {};
                  for (var doc in restockDocs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final pId = data['productId'] ?? 'unknown';
                    totalInvestedMap[pId] = (totalInvestedMap[pId] ?? 0) + ((data['amount'] as num?)?.toDouble() ?? 0.0);
                  }

                  final formatter = NumberFormat('#,##0.00');

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final pDoc = products[index];
                      final pData = pDoc.data() as Map<String, dynamic>;
                      final name = pData['name'] ?? 'Unknown';
                      final stock = (pData['stock'] as num?)?.toInt() ?? 0;
                      final weight = (pData['weight'] as num?)?.toDouble() ?? 0.0;
                      
                      final totalInvested = totalInvestedMap[pDoc.id] ?? 0.0;
                      final currentStockValue = stock * weight * marketRate * 0.7;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Stock on Hand:'),
                                  Text('$stock units', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total Invested (Historical):'),
                                  Text('฿${formatter.format(totalInvested)}', 
                                    style: const TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Current Stock Value (at Cost):'),
                                  Text('฿${formatter.format(currentStockValue)}', 
                                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
