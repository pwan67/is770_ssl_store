import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'owner_wallets_page.dart';
import 'owner_pawns_page.dart';
import 'owner_products_page.dart';
import 'owner_savings_page.dart';
import 'owner_sales_thb_page.dart';
import 'owner_sales_qty_page.dart';
import 'owner_inventory_cost_page.dart';

class OwnerOverviewTab extends StatefulWidget {
  const OwnerOverviewTab({super.key});

  @override
  State<OwnerOverviewTab> createState() => _OwnerOverviewTabState();
}

class _OwnerOverviewTabState extends State<OwnerOverviewTab> {
  DateTimeRange? _selectedDateRange;

  @override
  Widget build(BuildContext context) {
    String dateRangeText = 'All Time';
    if (_selectedDateRange != null) {
      dateRangeText =
          '${DateFormat('MMM d, yyyy').format(_selectedDateRange!.start)} - ${DateFormat('MMM d, yyyy').format(_selectedDateRange!.end)}';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF800000),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDateRange: _selectedDateRange,
                  );
                  if (result != null) {
                    setState(() {
                      // Adjust end date to include the whole day
                      _selectedDateRange = DateTimeRange(
                        start: result.start,
                        end: DateTime(
                          result.end.year,
                          result.end.month,
                          result.end.day,
                          23,
                          59,
                          59,
                        ),
                      );
                    });
                  }
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(dateRangeText),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetricsGrid(context),
          const SizedBox(height: 32),
          const Text(
            'Recent Global Activity',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildRecentActivityList(),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sales Performance',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _MetricCard(
              title: 'Total Sales (THB)',
              icon: Icons.monetization_on,
              color: Colors.blueAccent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      OwnerSalesThbPage(dateRange: _selectedDateRange),
                ),
              ),
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('type', isEqualTo: 'buy')
                  .snapshots()
                  .map((snap) {
                    double total = 0.0;
                    for (var doc in snap.docs) {
                      final data = doc.data();
                      final timestamp = (data['timestamp'] as Timestamp?)
                          ?.toDate();
                      if (_selectedDateRange != null && timestamp != null) {
                        if (timestamp.isBefore(_selectedDateRange!.start) ||
                            timestamp.isAfter(_selectedDateRange!.end)) {
                          continue;
                        }
                      }
                      total += (data['amount'] as num?)?.toDouble() ?? 0.0;
                    }
                    if (total >= 1000000) {
                      return '฿${(total / 1000000).toStringAsFixed(1)}M';
                    } else if (total >= 1000) {
                      return '฿${(total / 1000).toStringAsFixed(1)}k';
                    }
                    return '฿${total.toStringAsFixed(0)}';
                  }),
            ),
            _MetricCard(
              title: 'Total Sales (Qty)',
              icon: Icons.shopping_bag,
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      OwnerSalesQtyPage(dateRange: _selectedDateRange),
                ),
              ),
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('type', isEqualTo: 'buy')
                  .snapshots()
                  .map((snap) {
                    int count = 0;
                    for (var doc in snap.docs) {
                      final data = doc.data();
                      final timestamp = (data['timestamp'] as Timestamp?)
                          ?.toDate();
                      if (_selectedDateRange != null && timestamp != null) {
                        if (timestamp.isBefore(_selectedDateRange!.start) ||
                            timestamp.isAfter(_selectedDateRange!.end)) {
                          continue;
                        }
                      }
                      count++;
                    }
                    return count.toString();
                  }),
            ),
            _MetricCard(
              title: 'Total Cost (THB)',
              icon: Icons.payments,
              color: Colors.redAccent,
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('type', isEqualTo: 'buy')
                  .snapshots()
                  .map((snap) {
                    double total = 0.0;
                    for (var doc in snap.docs) {
                      final data = doc.data();
                      final timestamp = (data['timestamp'] as Timestamp?)
                          ?.toDate();
                      if (_selectedDateRange != null && timestamp != null) {
                        if (timestamp.isBefore(_selectedDateRange!.start) ||
                            timestamp.isAfter(_selectedDateRange!.end)) {
                          continue;
                        }
                      }
                      total += (data['cost'] as num?)?.toDouble() ?? 0.0;
                    }
                    if (total >= 1000000) {
                      return '฿${(total / 1000000).toStringAsFixed(1)}M';
                    } else if (total >= 1000) {
                      return '฿${(total / 1000).toStringAsFixed(1)}k';
                    }
                    return '฿${total.toStringAsFixed(0)}';
                  }),
            ),
            _MetricCard(
              title: 'Total Profit (THB)',
              icon: Icons.trending_up,
              color: Colors.green,
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('type', isEqualTo: 'buy')
                  .snapshots()
                  .map((snap) {
                    double total = 0.0;
                    for (var doc in snap.docs) {
                      final data = doc.data();
                      final timestamp = (data['timestamp'] as Timestamp?)
                          ?.toDate();
                      if (_selectedDateRange != null && timestamp != null) {
                        if (timestamp.isBefore(_selectedDateRange!.start) ||
                            timestamp.isAfter(_selectedDateRange!.end)) {
                          continue;
                        }
                      }
                      total += (data['profit'] as num?)?.toDouble() ?? 0.0;
                    }
                    bool isNegative = total < 0;
                    double absTotal = total.abs();
                    String prefix = isNegative ? '-฿' : '฿';
                    
                    String formatted;
                    if (absTotal >= 1000000) {
                      formatted = '${(absTotal / 1000000).toStringAsFixed(1)}M';
                    } else if (absTotal >= 1000) {
                      formatted = '${(absTotal / 1000).toStringAsFixed(1)}k';
                    } else {
                      formatted = absTotal.toStringAsFixed(0);
                    }
                    return '$prefix$formatted';
                  }),
            ),
          ],
        ),

        const SizedBox(height: 24),
        const Text(
          'Store Assets',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _MetricCard(
              title: 'Wallet Balances',
              icon: Icons.account_balance_wallet,
              color: Colors.purple,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OwnerWalletsPage()),
              ),
              stream: FirebaseFirestore.instance
                  .collection('wallets')
                  .snapshots()
                  .map((snap) {
                    double total = 0.0;
                    for (var doc in snap.docs) {
                      total +=
                          (doc.data()['balance'] as num?)?.toDouble() ?? 0.0;
                    }
                    if (total >= 1000000) {
                      return '฿${(total / 1000000).toStringAsFixed(1)}M';
                    } else if (total >= 1000) {
                      return '฿${(total / 1000).toStringAsFixed(1)}k';
                    }
                    return '฿${total.toStringAsFixed(0)}';
                  }),
            ),
            _MetricCard(
              title: 'Total Products',
              icon: Icons.inventory_2,
              color: Colors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OwnerProductsPage()),
              ),
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .snapshots()
                  .map((snap) => snap.docs.length.toString()),
            ),
            _MetricCard(
              title: 'Inventory Investment',
              icon: Icons.inventory,
              color: Colors.brown,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OwnerInventoryCostPage()),
              ),
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('type', isEqualTo: 'restock')
                  .snapshots()
                  .map((snap) {
                    double total = 0.0;
                    for (var doc in snap.docs) {
                      total += (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
                    }
                    if (total >= 1000000) {
                      return '฿${(total / 1000000).toStringAsFixed(1)}M';
                    } else if (total >= 1000) {
                      return '฿${(total / 1000).toStringAsFixed(1)}k';
                    }
                    return '฿${total.toStringAsFixed(0)}';
                  }),
            ),
            _MetricCard(
              title: 'Inventory Value',
              icon: Icons.account_balance_wallet,
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OwnerInventoryCostPage()),
              ),
              stream: FirebaseFirestore.instance
                  .collection('market')
                  .doc('gold_rate')
                  .snapshots()
                  .asyncMap((rateDoc) async {
                    final data = rateDoc.data();
                    final marketRate = (data?['sellPrice'] as num?)?.toDouble() ?? 42000.0;
                    
                    final productSnap = await FirebaseFirestore.instance.collection('products').get();
                    double totalValue = 0.0;
                    for (var doc in productSnap.docs) {
                      final pData = doc.data();
                      final stock = (pData['stock'] as num?)?.toInt() ?? 0;
                      final weight = (pData['weight'] as num?)?.toDouble() ?? 0.0;
                      totalValue += stock * weight * marketRate * 0.7;
                    }
                    
                    if (totalValue >= 1000000) {
                      return '฿${(totalValue / 1000000).toStringAsFixed(1)}M';
                    } else if (totalValue >= 1000) {
                      return '฿${(totalValue / 1000).toStringAsFixed(1)}k'; 
                    }
                    return '฿${totalValue.toStringAsFixed(0)}';
                  }),
            ),
          ],
        ),

        const SizedBox(height: 24),
        const Text(
          'Store Debts / Liabilities',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _MetricCard(
              title: 'Active Pawns',
              icon: Icons.real_estate_agent,
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OwnerPawnsPage()),
              ),
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('type', isEqualTo: 'pawn')
                  .snapshots()
                  .map((snap) => snap.docs.length.toString()),
            ),
            _MetricCard(
              title: 'Gold Savings (Payable)',
              icon: Icons.savings,
              color: Colors.teal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OwnerSavingsPage()),
              ),
              stream: FirebaseFirestore.instance
                  .collectionGroup('savings')
                  .snapshots()
                  .asyncMap((snap) async {
                    double totalWeight = 0.0;
                    for (var doc in snap.docs) {
                      if (doc.id == 'account') {
                        final data = doc.data() as Map<String, dynamic>;
                        totalWeight +=
                            (data['totalWeightSaved'] as num?)?.toDouble() ??
                            0.0;
                      }
                    }
                    final rateDoc = await FirebaseFirestore.instance
                        .collection('market')
                        .doc('gold_rate')
                        .get();
                    final data = rateDoc.data();
                    final sellPrice =
                        (data?['sellPrice'] as num?)?.toDouble() ?? 40000.0;
                    final totalValues = totalWeight * sellPrice;

                    if (totalValues >= 1000000) {
                      return '฿${(totalValues / 1000000).toStringAsFixed(1)}M';
                    } else if (totalValues >= 1000) {
                      return '฿${(totalValues / 1000).toStringAsFixed(1)}k';
                    }
                    return '฿${totalValues.toStringAsFixed(0)}';
                  }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivityList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No recent activity found.'));
        }

        final formatter = NumberFormat('#,##0.00');

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final typeStr = data['type'] as String? ?? 'unknown';
            final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
            final email = data['userEmail'] as String? ?? 'Unknown User';
            final details = data['details'] as String? ?? '';

            IconData icon;
            Color iconColor;
            if (typeStr == 'buy' ||
                typeStr == 'redeem' ||
                typeStr == 'savings_deposit') {
              icon = Icons.arrow_downward;
              iconColor = Colors.green; // Money coming in to store
            } else if (typeStr == 'sell' ||
                typeStr == 'pawn' ||
                typeStr == 'savings_withdraw') {
              icon = Icons.arrow_upward;
              iconColor = Colors.red; // Money going out from store
            } else {
              icon = Icons.swap_horiz;
              iconColor = Colors.grey;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: iconColor.withOpacity(0.2),
                  child: Icon(icon, color: iconColor),
                ),
                title: Text(
                  details,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(email),
                trailing: Text(
                  '฿${formatter.format(amount)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Stream<String> stream;
  final VoidCallback? onTap;

  const _MetricCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.stream,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const Spacer(),
                  StreamBuilder<String>(
                    stream: stream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      return Text(
                        snapshot.data ?? '0',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
