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
        // --- HERO SECTION (Critical KPIs) ---
        const Text(
          'Business Performance',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Total Profit',
                icon: Icons.trending_up,
                color: const Color(0xFF2E7D32),
                isHero: true,
                stream: FirebaseFirestore.instance
                    .collection('transactions')
                    .where('type', isEqualTo: 'buy')
                    .snapshots()
                    .map((snap) {
                  double total = 0.0;
                  for (var doc in snap.docs) {
                    final data = doc.data();
                    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                    if (_selectedDateRange != null && timestamp != null) {
                      if (timestamp.isBefore(_selectedDateRange!.start) ||
                          timestamp.isAfter(_selectedDateRange!.end)) {
                        continue;
                      }
                    }
                    total += (data['profit'] as num?)?.toDouble() ?? 0.0;
                  }
                  return _formatCurrency(total);
                }),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MetricCard(
                title: 'Total Revenue',
                icon: Icons.monetization_on,
                color: const Color(0xFF1A237E),
                isHero: true,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OwnerSalesThbPage(dateRange: _selectedDateRange),
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
                    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                    if (_selectedDateRange != null && timestamp != null) {
                      if (timestamp.isBefore(_selectedDateRange!.start) ||
                          timestamp.isAfter(_selectedDateRange!.end)) {
                        continue;
                      }
                    }
                    total += (data['amount'] as num?)?.toDouble() ?? 0.0;
                  }
                  return _formatCurrency(total);
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _MetricCard(
              title: 'Sales Count',
              icon: Icons.shopping_bag,
              color: const Color(0xFF1976D2),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => OwnerSalesQtyPage(dateRange: _selectedDateRange),
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
                  final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
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
              title: 'Total Cost (COGS)',
              icon: Icons.payments,
              color: const Color(0xFFC62828),
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('type', isEqualTo: 'buy')
                  .snapshots()
                  .map((snap) {
                double total = 0.0;
                for (var doc in snap.docs) {
                  final data = doc.data();
                  final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
                  if (_selectedDateRange != null && timestamp != null) {
                    if (timestamp.isBefore(_selectedDateRange!.start) ||
                        timestamp.isAfter(_selectedDateRange!.end)) {
                      continue;
                    }
                  }
                  total += (data['cost'] as num?)?.toDouble() ?? 0.0;
                }
                return _formatCurrency(total);
              }),
            ),
          ],
        ),

        // --- STORE EQUITY ---
        const SizedBox(height: 32),
        const Text(
          'Store Equity & Assets',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _MetricCard(
              title: 'Wallet Balances',
              icon: Icons.account_balance_wallet,
              color: const Color(0xFF6A1B9A),
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
                  total += (doc.data()['balance'] as num?)?.toDouble() ?? 0.0;
                }
                return _formatCurrency(total);
              }),
            ),
            _MetricCard(
              title: 'Inventory Value',
              icon: Icons.auto_graph,
              color: const Color(0xFFEF6C00),
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
                return _formatCurrency(totalValue);
              }),
            ),
            _MetricCard(
              title: 'Stock Investment',
              icon: Icons.inventory,
              color: const Color(0xFF4E342E),
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
                return _formatCurrency(total);
              }),
            ),
            _MetricCard(
              title: 'Product Types',
              icon: Icons.inventory_2,
              color: const Color(0xFF2E7D32),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OwnerProductsPage()),
              ),
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .snapshots()
                  .map((snap) => snap.docs.length.toString()),
            ),
          ],
        ),

        // --- LIABILITIES ---
        const SizedBox(height: 32),
        const Text(
          'Store Liabilities',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.3,
          children: [
            _MetricCard(
              title: 'Active Pawns',
              icon: Icons.real_estate_agent,
              color: const Color(0xFFE65100),
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
              title: 'Savings Liability',
              icon: Icons.savings,
              color: const Color(0xFF00695C),
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
                    totalWeight += (data['totalWeightSaved'] as num?)?.toDouble() ?? 0.0;
                  }
                }
                final rateDoc = await FirebaseFirestore.instance.collection('market').doc('gold_rate').get();
                final sellPrice = (rateDoc.data()?['sellPrice'] as num?)?.toDouble() ?? 40000.0;
                return _formatCurrency(totalWeight * sellPrice);
              }),
            ),
          ],
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    bool isNegative = amount < 0;
    double absAmount = amount.abs();
    String prefix = isNegative ? '-฿' : '฿';
    if (absAmount >= 1000000) {
      return '$prefix${(absAmount / 1000000).toStringAsFixed(1)}M';
    } else if (absAmount >= 1000) {
      return '$prefix${(absAmount / 1000).toStringAsFixed(1)}k';
    }
    return '$prefix${absAmount.toStringAsFixed(0)}';
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
            if (['buy', 'redeem', 'savings_deposit'].contains(typeStr)) {
              icon = Icons.arrow_downward;
              iconColor = Colors.green;
            } else if (['sell', 'pawn', 'savings_withdraw'].contains(typeStr)) {
              icon = Icons.arrow_upward;
              iconColor = Colors.red;
            } else {
              icon = Icons.swap_horiz;
              iconColor = Colors.grey;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: iconColor.withOpacity(0.1),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                title: Text(
                  details,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(email, style: const TextStyle(fontSize: 12)),
                trailing: Text(
                  '฿${formatter.format(amount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: iconColor,
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
  final bool isHero;

  const _MetricCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.stream,
    this.onTap,
    this.isHero = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isHero ? color : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isHero ? 0.3 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: !isHero ? Border.all(color: Colors.grey[200]!) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isHero ? 16.0 : 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (isHero ? Colors.white : color).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: isHero ? Colors.white : color,
                        size: isHero ? 24 : 18,
                      ),
                    ),
                    if (onTap != null)
                      Icon(
                        Icons.chevron_right,
                        color: (isHero ? Colors.white : Colors.grey).withOpacity(0.5),
                        size: 16,
                      ),
                  ],
                ),
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StreamBuilder<String>(
                      stream: stream,
                      builder: (context, snapshot) {
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            snapshot.data ?? '--',
                            style: TextStyle(
                              fontSize: isHero ? 22 : 18,
                              fontWeight: FontWeight.bold,
                              color: isHero ? Colors.white : Colors.black87,
                              letterSpacing: -0.5,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 2),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isHero ? 13 : 11,
                        fontWeight: FontWeight.w600,
                        color: (isHero ? Colors.white : Colors.grey[600])!.withOpacity(0.8),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
