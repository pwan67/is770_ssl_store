import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/mock_service.dart';
import '../models/gold_asset.dart';
import '../models/gold_transaction.dart';
import '../models/gold_rate.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key});

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  final MockService _service = MockService();
  final AuthService _authService = AuthService();
  late Stream<GoldRate> _goldRateStream;
  GoldRate? _currentRate;

  @override
  void initState() {
    super.initState();
    _goldRateStream = _service.getGoldRateStream();
    _goldRateStream.listen((rate) {
      if (mounted) setState(() => _currentRate = rate);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Gold Portfolio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          )
        ],
      ),
      body: StreamBuilder<User?>(
        stream: _authService.user,
        builder: (context, authSnapshot) {
          if (authSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!authSnapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                   const SizedBox(height: 16),
                   const Text('Please login to view your Portfolio', style: TextStyle(fontSize: 18)),
                   const SizedBox(height: 24),
                   ElevatedButton(
                     onPressed: () => Navigator.pushNamed(context, '/login'),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: const Color(0xFF800000),
                       foregroundColor: Colors.white,
                     ),
                     child: const Text('Login / Sign Up'),
                   )
                ],
              ),
            );
          }

          return StreamBuilder<List<GoldAsset>>(
            stream: _service.getMemberAssetsStream(),
            builder: (context, assetSnapshot) {
              if (assetSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final assets = assetSnapshot.data ?? [];
              final totalWeight = assets.fold(0.0, (sum, item) => sum + item.weight);
              final totalValue = totalWeight * (_currentRate?.buyPrice ?? 0);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Summary Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF800000), Color(0xFFA00000)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text('Total Accumulated Weight', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('${totalWeight.toStringAsFixed(2)} Baht', 
                            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                          const Divider(color: Colors.white24, height: 32),
                          const Text('Estimated Value', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: 8),
                          Text('฿ ${totalValue.toInt()}', 
                            style: const TextStyle(color: Color(0xFFFFD700), fontSize: 28, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Asset List
                    _SectionHeader(title: 'My Assets (${assets.length})'),
                    const SizedBox(height: 12),
                    if (assets.isEmpty)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('No gold assets yet.\nStart buying to build your portfolio!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      ))
                    else
                      ...assets.map((asset) => _AssetCard(asset: asset, currentRate: _currentRate)),

                    const SizedBox(height: 32),
                    
                    // Transaction History
                    const _SectionHeader(title: 'Recent Transactions'),
                    const SizedBox(height: 12),
                    
                    StreamBuilder<List<GoldTransaction>>(
                      stream: _service.getTransactionHistoryStream(),
                      builder: (context, txSnapshot) {
                        if (txSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        
                        final transactions = txSnapshot.data ?? [];
                        if (transactions.isEmpty) {
                          return const Center(child: Text('No recent transactions', style: TextStyle(color: Colors.grey)));
                        }

                        return ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: transactions.length,
                          separatorBuilder: (context, index) => const Divider(),
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            final isBuy = tx.type == TransactionType.buy;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isBuy ? Colors.green[50] : Colors.red[50], 
                                  shape: BoxShape.circle
                                ),
                                child: Icon(
                                  isBuy ? Icons.add : Icons.remove, 
                                  color: isBuy ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                              ),
                              title: Text(tx.details),
                              subtitle: Text('${tx.timestamp.day}/${tx.timestamp.month}/${tx.timestamp.year}'),
                              trailing: Text(
                                '฿ ${tx.amount.toInt()}', 
                                style: TextStyle(fontWeight: FontWeight.bold, color: isBuy ? Colors.green : Colors.red)
                              ),
                            );
                          },
                        );
                      }
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              );
            }
          );
        }
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF800000)));
  }
}

class _AssetCard extends StatelessWidget {
  final GoldAsset asset;
  final GoldRate? currentRate;
  const _AssetCard({required this.asset, this.currentRate});

  @override
  Widget build(BuildContext context) {
    double currentVal = asset.weight * (currentRate?.buyPrice ?? 0);
    double profit = currentVal - asset.acquisitionPrice;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFFFFF8E1), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.workspace_premium, color: Color(0xFF800000)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(asset.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${asset.weight} Baht • Acquired ฿ ${asset.acquisitionPrice.toInt()}', 
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('฿ ${currentVal.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  '${profit >= 0 ? "+" : ""}฿ ${profit.toInt()}', 
                  style: TextStyle(fontSize: 12, color: profit >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
