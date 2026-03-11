import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OwnerPawnsPage extends StatelessWidget {
  const OwnerPawnsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Active Pawns')),
      body: StreamBuilder<List<DocumentSnapshot>>(
        stream: FirebaseFirestore.instance
            .collection('transactions')
            .where('type', isEqualTo: 'pawn')
            .snapshots()
            .map((snap) {
              final docs = snap.docs.toList();
              docs.sort((a, b) {
                final t1 =
                    (a.data() as Map<String, dynamic>)['timestamp']
                        as Timestamp?;
                final t2 =
                    (b.data() as Map<String, dynamic>)['timestamp']
                        as Timestamp?;
                if (t1 == null || t2 == null) return 0;
                return t2.compareTo(t1); // descending
              });
              return docs;
            }),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || snapshot.data!.isEmpty)
            return const Center(child: Text('No active pawns found.'));

          final formatter = NumberFormat('#,##0.00');

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data![index];
              final data = doc.data() as Map<String, dynamic>;
              final details = data['details'] ?? 'Unknown Data';
              final userEmail = data['userEmail'] ?? 'Unknown Email';
              final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
              final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.real_estate_agent),
                  ),
                  title: Text(
                    details,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '$userEmail\n${timestamp != null ? DateFormat('MMM dd, yyyy').format(timestamp) : 'Unknown Date'}',
                  ),
                  isThreeLine: true,
                  trailing: Text(
                    '฿${formatter.format(amount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.orange,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
