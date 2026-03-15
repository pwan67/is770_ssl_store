import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OwnerPawnsPage extends StatefulWidget {
  const OwnerPawnsPage({super.key});

  @override
  State<OwnerPawnsPage> createState() => _OwnerPawnsPageState();
}

class _OwnerPawnsPageState extends State<OwnerPawnsPage> {
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Pawns'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: ['All', 'Overdue', 'Due Soon'].map((f) {
                final isSelected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _filter = f),
                    selectedColor: Colors.orange.withOpacity(0.2),
                    checkmarkColor: Colors.orange,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collectionGroup('assets')
            .where('status', isEqualTo: 'pawned')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final now = DateTime.now();
          final soonThreshold = now.add(const Duration(days: 7));
          
          List<Map<String, dynamic>> items = [];
          
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            items = snapshot.data!.docs.map((d) => d.data() as Map<String, dynamic>).toList();
            return _buildList(context, items, now, soonThreshold);
          } else {
            // Fallback: Query transactions if no assets found
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('type', isEqualTo: 'pawn')
                  .snapshots(),
              builder: (context, txSnapshot) {
                if (txSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!txSnapshot.hasData || txSnapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No active pawns found.'));
                }
                
                final txDocs = txSnapshot.data!.docs.toList();
                // Map transactions to pseudo-assets
                return _buildList(context, txDocs.map((tx) {
                  final data = tx.data() as Map<String, dynamic>;
                  final timestamp = (data['timestamp'] as Timestamp?) ?? Timestamp.now();
                  return {
                    'name': data['details']?.toString().split(':').last.trim() ?? 'Pawned Item',
                    'weight': (data['weight'] as num?)?.toDouble() ?? 0.0,
                    'loanAmount': (data['amount'] as num?)?.toDouble() ?? 0.0,
                    'pawnDate': timestamp,
                    'dueDate': Timestamp.fromDate(timestamp.toDate().add(const Duration(days: 30))),
                    'status': 'pawned',
                  };
                }).toList(), now, soonThreshold);
              },
            );
          }
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Map<String, dynamic>> items, DateTime now, DateTime soonThreshold) {
    var filteredItems = items;

    // Apply Filter
    if (_filter == 'Overdue') {
      filteredItems = filteredItems.where((data) {
        final dueDate = data['dueDate'] as Timestamp?;
        return dueDate != null && dueDate.toDate().isBefore(now);
      }).toList();
    } else if (_filter == 'Due Soon') {
      filteredItems = filteredItems.where((data) {
        final dueDate = data['dueDate'] as Timestamp?;
        return dueDate != null && 
               dueDate.toDate().isAfter(now) && 
               dueDate.toDate().isBefore(soonThreshold);
      }).toList();
    }

    // Sort descending by pawnDate
    filteredItems.sort((a, b) {
      final t1 = a['pawnDate'] as Timestamp?;
      final t2 = b['pawnDate'] as Timestamp?;
      return (t2 ?? Timestamp(0, 0)).compareTo(t1 ?? Timestamp(0, 0));
    });

    if (filteredItems.isEmpty) {
      return Center(child: Text('No $_filter pawns found.'));
    }

    final formatter = NumberFormat('#,##0.00');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final data = filteredItems[index];
        final name = data['name'] ?? 'Unknown Item';
        final weight = (data['weight'] as num?)?.toDouble() ?? 0.0;
        final loanAmount = (data['loanAmount'] as num?)?.toDouble() ?? 0.0;
        final pawnDate = (data['pawnDate'] as Timestamp?)?.toDate();
        final dueDate = (data['dueDate'] as Timestamp?)?.toDate();

        bool isOverdue = dueDate != null && dueDate.isBefore(now);
        bool isDueSoon = dueDate != null && !isOverdue && dueDate.isBefore(soonThreshold);

        Color statusColor = Colors.grey;
        String statusLabel = 'ACTIVE';
        if (isOverdue) {
          statusColor = Colors.red;
          statusLabel = 'OVERDUE';
        } else if (isDueSoon) {
          statusColor = Colors.orange;
          statusLabel = 'DUE SOON';
        }

        return Card(
          elevation: isOverdue ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: statusColor.withOpacity(0.3),
              width: isOverdue ? 2 : 1,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: CircleAvatar(
              backgroundColor: statusColor.withOpacity(0.1),
              child: Icon(Icons.real_estate_agent, color: statusColor),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text('Weight: ${weight.toStringAsFixed(2)} Baht'),
                Text(
                  'Pawned: ${pawnDate != null ? DateFormat('MMM dd, yyyy').format(pawnDate) : '-'}',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Due: ${dueDate != null ? DateFormat('MMM dd, yyyy').format(dueDate) : '-'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isOverdue || isDueSoon ? FontWeight.bold : FontWeight.normal,
                    color: statusColor == Colors.grey ? Colors.black54 : statusColor,
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'Loan Amount',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  '฿${formatter.format(loanAmount)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: statusColor == Colors.red ? Colors.red : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
