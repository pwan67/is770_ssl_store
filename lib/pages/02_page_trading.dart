import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../models/gold_asset.dart';
import '../models/gold_rate.dart';
import '../models/gold_transaction.dart';
import '../services/mock_service.dart';
import '../widgets/gold_rate_card.dart';

class TradingPage extends StatefulWidget {
  final int initialTabIndex;
  const TradingPage({super.key, this.initialTabIndex = 0});

  @override
  State<TradingPage> createState() => _TradingPageState();
}

class _TradingPageState extends State<TradingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MockService _service = MockService();
  final AuthService _authService = AuthService();
  late Stream<GoldRate> _goldRateStream;
  GoldRate? _currentRate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    _goldRateStream = _service.getGoldRateStream();
    _goldRateStream.listen((rate) {
      if (mounted) setState(() => _currentRate = rate);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.user,
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!authSnapshot.hasData) {
           return Scaffold(
            appBar: AppBar(title: const Text('Trading & Services')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                   const SizedBox(height: 16),
                   const Text('Please login to access Trading & Services', style: TextStyle(fontSize: 18)),
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
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Trading & Services'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Buy', icon: Icon(Icons.shopping_cart)),
                Tab(text: 'Sell', icon: Icon(Icons.sell)),
                Tab(text: 'Pawn', icon: Icon(Icons.account_balance_wallet)),
              ],
              labelColor: const Color(0xFFFFD700),
              unselectedLabelColor: Colors.white70,
              indicatorColor: const Color(0xFFFFD700),
            ),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: _currentRate != null 
                  ? GoldRateCard(rate: _currentRate!)
                  : const Center(child: CircularProgressIndicator()),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _BuyTab(service: _service, currentRate: _currentRate),
                    _SellTab(service: _service, currentRate: _currentRate),
                    _PawnTab(service: _service, currentRate: _currentRate),
                  ],
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

// -- Buy Tab --
class _BuyTab extends StatefulWidget {
  final MockService service;
  final GoldRate? currentRate;
  const _BuyTab({required this.service, this.currentRate});

  @override
  State<_BuyTab> createState() => _BuyTabState();
}

class _BuyTabState extends State<_BuyTab> {
  double _weight = 1.0;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    if (widget.currentRate == null) return const Center(child: CircularProgressIndicator());
    
    double total = _weight * widget.currentRate!.sellPrice;
    final formatter = NumberFormat('#,##0');

    return StreamBuilder<double>(
      stream: widget.service.getWalletBalanceStream(),
      builder: (context, snapshot) {
        final balance = snapshot.data ?? 0.0;
        final hasEnoughFunds = balance >= total;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Wallet Balance Header
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD700)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Wallet Balance:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('฿ ${formatter.format(balance)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                    ],
                  ),
                ),
              ),

          const Text('Select Weight (Baht)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Slider(
            value: _weight,
            min: 0.25,
            max: 10,
            divisions: 39,
            label: '$_weight Baht',
            activeColor: const Color(0xFF800000),
            onChanged: (val) => setState(() => _weight = val),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$_weight Baht', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF800000))),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF800000).withOpacity(0.2)),
            ),
            child: Column(
              children: [
                const Text('Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF600000))),
                const SizedBox(height: 16),
                _rowItem('Selling Price', '฿ ${formatter.format(widget.currentRate!.sellPrice)} / Baht'),
                const Divider(),
                _rowItem('Total Amount', '฿ ${formatter.format(total)}', isBold: true),
                if (balance >= total)
                  _rowItem('Estimated Remaining Balance', '฿ ${formatter.format(balance - total)}', isBold: true),
              ],
            ),
          ),
          const SizedBox(height: 48),
          if (!hasEnoughFunds)
            const Padding(
              padding: EdgeInsets.only(bottom: 16.0),
              child: Text(
                'Insufficient funds. Please deposit money in My Gold tab.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ),
          ElevatedButton(
            onPressed: (_isProcessing || !hasEnoughFunds) ? null : () async {
              setState(() => _isProcessing = true);
                try {
                  String? productId;
                  if (_weight == 0.25) productId = 'p_bar_025';
                  else if (_weight == 0.5) productId = 'p_bar_05';
                  else if (_weight == 1.0) productId = 'p_bar_1';
                  else if (_weight == 2.0) productId = 'p_bar_2';
                  else if (_weight == 5.0) productId = 'p_bar_5';
                  else if (_weight == 10.0) productId = 'p_bar_10';

                  await widget.service.createTransaction(
                    assetName: 'Gold Bar ($_weight Baht)',
                    weight: _weight,
                    amount: total,
                    type: TransactionType.buy,
                    category: 'Gold Bar',
                    productId: productId,
                  );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Purchase Successful!')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isProcessing = false);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: hasEnoughFunds ? const Color(0xFF800000) : Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isProcessing 
              ? const CircularProgressIndicator(color: Colors.white) 
              : const Text('Confirm Purchase', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _rowItem(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

// -- Sell Tab --
class _SellTab extends StatefulWidget {
  final MockService service;
  final GoldRate? currentRate;
  const _SellTab({required this.service, this.currentRate});

  @override
  State<_SellTab> createState() => _SellTabState();
}

class _SellTabState extends State<_SellTab> {
  bool _isProcessing = false;

  void _showSellConfirmation(BuildContext context, GoldAsset asset, double estimatedValue) {
    final formatter = NumberFormat('#,##0');
    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
             return AlertDialog(
              title: const Text('Confirm Sale'),
              content: StreamBuilder<double>(
                stream: widget.service.getWalletBalanceStream(),
                builder: (context, snapshot) {
                  final walletBalance = snapshot.data ?? 0.0;
                  final newBalance = walletBalance + estimatedValue;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Asset: ${asset.name}'),
                      Text('Weight: ${asset.weight} Baht'),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Credit to Wallet:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('+ ฿ ${formatter.format(estimatedValue)}', style: const TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold)),
                        ]),
                      ),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('New Wallet Balance:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('฿ ${formatter.format(newBalance)}', style: const TextStyle(color: Colors.blue, fontSize: 18, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 16),
                      const Text('Are you sure you want to sell this asset? This action cannot be undone.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  );
                }
              ),
              actions: [
                TextButton(
                  onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isProcessing ? null : () async {
                    setStateDialog(() => _isProcessing = true);
                    setState(() => _isProcessing = true); // Update underlying tab state too (optional, for safety)
                    
                    try {
                       await widget.service.sellAsset(asset: asset, sellPrice: estimatedValue);
                       if (mounted) {
                          Navigator.of(context).pop(); // Close dialog
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asset Sold Successfully!')));
                       }
                    } catch (e) {
                      if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error selling asset: $e')));
                      }
                    } finally {
                       if (mounted) {
                          setStateDialog(() => _isProcessing = false);
                          setState(() => _isProcessing = false);
                       }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: _isProcessing 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm Sell', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0');
    return StreamBuilder<List<GoldAsset>>(
      stream: widget.service.getMemberAssetsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        final assets = snapshot.data ?? [];
        if (assets.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('No assets to sell.', style: TextStyle(color: Colors.grey)),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: assets.length,
          itemBuilder: (context, index) {
            final asset = assets[index];
            final estimatedValue = asset.weight * (widget.currentRate?.buyPrice ?? 0);
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFFFFD700), child: Icon(Icons.sell, color: Color(0xFF800000))),
                title: Text(asset.name),
                subtitle: Text('${asset.weight} Baht'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('EST. VALUE', style: TextStyle(fontSize: 10, color: Colors.grey)),
                    Text('฿ ${formatter.format(estimatedValue)}', 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
                onTap: _isProcessing ? null : () => _showSellConfirmation(context, asset, estimatedValue),
              ),
            );
          },
        );
      },
    );
  }
}

class _PawnTab extends StatefulWidget {
  final MockService service;
  final GoldRate? currentRate;
  const _PawnTab({required this.service, this.currentRate});

  @override
  State<_PawnTab> createState() => _PawnTabState();
}

class _PawnTabState extends State<_PawnTab> {
  bool _isProcessing = false;

  void _showPawnConfirmation(BuildContext context, GoldAsset asset, double maxLoan) {
    double requestedLoan = maxLoan;
    final formatter = NumberFormat('#,##0');
    final TextEditingController _loanController = TextEditingController(text: maxLoan.toStringAsFixed(0));
    final String errorMsg = 'Amount must be between 1 and ${formatter.format(maxLoan)}';

    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
             bool isValid = requestedLoan > 0 && requestedLoan <= maxLoan;
             
             return AlertDialog(
              title: const Text('Confirm Pawn'),
              content: StreamBuilder<double>(
                stream: widget.service.getWalletBalanceStream(),
                builder: (context, snapshot) {
                  final walletBalance = snapshot.data ?? 0.0;
                  final newBalance = walletBalance + (isValid ? requestedLoan : 0);
                  
                  final dueDate = DateTime.now().add(const Duration(days: 30));
                  final formattedDate = '${dueDate.day}/${dueDate.month}/${dueDate.year}';

                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Asset: ${asset.name}'),
                        Text('Weight: ${asset.weight} Baht'),
                        const SizedBox(height: 12),
                        const Text('Requested Loan Amount (THB):', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _loanController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Desired Loan Amount (฿)',
                            border: const OutlineInputBorder(),
                            suffixText: 'Max: ${formatter.format(maxLoan)}',
                            errorText: (!isValid && _loanController.text.isNotEmpty) ? errorMsg : null,
                          ),
                          onChanged: (val) {
                            setStateDialog(() {
                              requestedLoan = double.tryParse(val) ?? 0.0;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('Credit to Wallet:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('+ ฿ ${formatter.format(requestedLoan)}', style: const TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          const Text('New Wallet Balance:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('฿ ${formatter.format(newBalance)}', style: const TextStyle(color: Colors.blue, fontSize: 18, fontWeight: FontWeight.bold)),
                        ]),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.orange[50],
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Due Date: $formattedDate (30 Days)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange)),
                              const Text('Interest rate is 1.25% per month. Late payments incur a 2% monthly penalty.', style: TextStyle(fontSize: 10, color: Colors.black87)),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                }
              ),
              actions: [
                TextButton(
                  onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (_isProcessing || !isValid) ? null : () async {
                    setStateDialog(() => _isProcessing = true);
                    setState(() => _isProcessing = true);
                    
                    try {
                       await widget.service.pawnAsset(asset: asset, loanAmount: requestedLoan);
                       if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Asset Pawned! ฿${formatter.format(requestedLoan)} added to Wallet.')));
                       }
                    } catch (e) {
                      if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error pawning asset: $e')));
                      }
                    } finally {
                       if (mounted) {
                          setStateDialog(() => _isProcessing = false);
                          setState(() => _isProcessing = false);
                       }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF800000)),
                  child: _isProcessing 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm Pawn', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0');
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: const Color(0xFFFFF8E1),
          child: Row(
            children: const [
              Icon(Icons.info_outline, color: Color(0xFF800000)),
              SizedBox(width: 12),
              Expanded(child: Text('Interest rate: 1.25% per month. Loan up to 85% of market value.', style: TextStyle(fontSize: 12))),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<GoldAsset>>(
            stream: widget.service.getMemberAssetsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              
              final allAssets = snapshot.data ?? [];
              final ownedAssets = allAssets.where((a) => a.status == 'owned').toList();

              if (ownedAssets.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('You have no fully owned assets available to pawn.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: ownedAssets.length,
                itemBuilder: (context, index) {
                  final asset = ownedAssets[index];
                  final currentVal = asset.weight * (widget.currentRate?.buyPrice ?? 0);
                  final maxLoan = widget.service.calculatePawnLoan(asset.weight, widget.currentRate?.buyPrice ?? 0);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Color(0xFFFFF8E1), child: Icon(Icons.shield, color: Color(0xFF800000))),
                      title: Text(asset.name),
                      subtitle: Text('${asset.weight} Baht • Valued at ฿${currentVal.toInt()}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Max Loan:', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          Text('฿ ${formatter.format(maxLoan)}', 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
                        ],
                      ),
                      onTap: _isProcessing ? null : () => _showPawnConfirmation(context, asset, maxLoan),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
