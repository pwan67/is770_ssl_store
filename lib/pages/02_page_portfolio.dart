import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/mock_service.dart';
import '../models/gold_asset.dart';
import '../models/gold_savings.dart';
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

  void _showTopUpDialog(BuildContext context) {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Deposit Funds'),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount (฿)', border: OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount > 0) {
                  await _service.addFunds(amount);
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      }
    );
  }

  void _showWithdrawDialog(BuildContext context, double maxBalance) {
    final TextEditingController amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Withdraw Funds'),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: 'Amount (Max: ฿${maxBalance.toStringAsFixed(0)})', border: const OutlineInputBorder()),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount > 0 && amount <= maxBalance) {
                  await _service.withdrawFunds(amount);
                  if (mounted) Navigator.pop(context);
                } else if (amount > maxBalance) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Insufficient funds')));
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      }
    );
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

          return StreamBuilder<GoldSavingsAccount>(
            stream: _service.getGoldSavingsAccountStream(),
            builder: (context, savingsSnapshot) {
              if (savingsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final savingsAccount = savingsSnapshot.data ?? GoldSavingsAccount(totalWeightSaved: 0, totalAmountInvested: 0, lastUpdated: DateTime.now());

              return StreamBuilder<List<GoldAsset>>(
                stream: _service.getMemberAssetsStream(),
                builder: (context, assetSnapshot) {
                  if (assetSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final assets = assetSnapshot.data ?? [];
                  final totalWeight = assets.fold(0.0, (sum, item) => sum + item.weight) + savingsAccount.totalWeightSaved;
                  final totalValue = totalWeight * (_currentRate?.buyPrice ?? 0);

                  return StreamBuilder<double>(
                    stream: _service.getWalletBalanceStream(),
                    builder: (context, walletSnapshot) {
                  final walletBalance = walletSnapshot.data ?? 0.0;
                  
                  // Asset List preparation
                  final ownedAssets = assets.where((a) => a.status == 'owned' || a.status == 'pickup_scheduled').toList();
                  final pawnedAssets = assets.where((a) => a.status == 'pawned').toList();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Wallet Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
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
                              const Text('My Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
                              const SizedBox(height: 8),
                              Text('฿ ${walletBalance.toStringAsFixed(0)}', 
                                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () => _showTopUpDialog(context),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Deposit'),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white, foregroundColor: Colors.green),
                                  ),
                                  const SizedBox(width: 16),
                                  OutlinedButton.icon(
                                    onPressed: () => _showWithdrawDialog(context, walletBalance),
                                    icon: const Icon(Icons.remove, size: 18),
                                    label: const Text('Withdraw'),
                                    style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        
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
                    
                    if (assets.isEmpty && savingsAccount.totalWeightSaved == 0) ...[
                      const _SectionHeader(title: 'My Assets (0)'),
                      const SizedBox(height: 12),
                      const Center(child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('No gold assets yet.\nStart buying to build your portfolio!', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                      ))
                    ] else ...[
                      if (savingsAccount.totalWeightSaved > 0) ...[
                        const _SectionHeader(title: 'Gold Savings (ออมทอง)'),
                        const SizedBox(height: 12),
                        _buildSavingsAssetCard(savingsAccount, _currentRate?.buyPrice ?? 40000.0),
                        const SizedBox(height: 16),
                      ],
                      if (ownedAssets.isNotEmpty) ...[
                        _SectionHeader(title: 'My Owned Gold (${ownedAssets.length})'),
                        const SizedBox(height: 12),
                        ...ownedAssets.map((asset) => _AssetCard(asset: asset, currentRate: _currentRate)),
                      ],
                      if (pawnedAssets.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _SectionHeader(title: 'My Pawned Gold (${pawnedAssets.length})'),
                        const SizedBox(height: 12),
                        ...pawnedAssets.map((asset) => _AssetCard(asset: asset, currentRate: _currentRate)),
                      ],
                    ],

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
      );
            }
          );
        }
      ),
    );
  }

  Widget _buildSavingsAssetCard(GoldSavingsAccount account, double currentBuyPrice) {
    double currentVal = account.totalWeightSaved * currentBuyPrice;
    double profit = currentVal - account.totalAmountInvested;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
            // Navigate directly to the Savings Page if they tap this
            Navigator.pushNamed(context, '/'); // Quick hack to jump, but preferably route to GoldSavingsPage
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manage on the Gold Savings page.')));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5), // Light purple for savings
                  borderRadius: BorderRadius.circular(10)
                ),
                child: const Icon(
                  Icons.savings, 
                  color: Color(0xFF8E24AA), // Deep purple
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Fractional Gold Savings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('${account.totalWeightSaved.toStringAsFixed(4)} Baht • Invested ฿${account.totalAmountInvested.toInt()}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
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

class _AssetCard extends StatefulWidget {
  final GoldAsset asset;
  final GoldRate? currentRate;
  const _AssetCard({required this.asset, this.currentRate});

  @override
  State<_AssetCard> createState() => _AssetCardState();
}

class _AssetCardState extends State<_AssetCard> {
  final MockService _service = MockService();
  bool _isProcessing = false;

  void _showRedeemConfirmation(BuildContext context, double principal, double interest, double penalty, double totalOwed) {
    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
             return AlertDialog(
              title: const Text('Redeem Pawned Asset'),
              content: StreamBuilder<double>(
                stream: _service.getWalletBalanceStream(),
                builder: (context, snapshot) {
                  final walletBalance = snapshot.data ?? 0.0;
                  final newBalance = walletBalance - totalOwed;
                  final hasEnoughFunds = walletBalance >= totalOwed;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Asset: ${widget.asset.name}'),
                      Text('Weight: ${widget.asset.weight} Baht'),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Principal Loan:'),
                          Text('฿ ${principal.toStringAsFixed(0)}'),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Standard Interest:'),
                          Text('฿ ${interest.toStringAsFixed(0)}'),
                        ],
                      ),
                      if (penalty > 0) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Overdue Penalty:', style: TextStyle(color: Colors.red)),
                            Text('฿ ${penalty.toStringAsFixed(0)}', style: const TextStyle(color: Colors.red)),
                          ],
                        ),
                      ],
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total to Pay:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('฿ ${totalOwed.toStringAsFixed(0)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (hasEnoughFunds) ...[
                        const Text('Estimated New Balance:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('฿ ${newBalance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold)),
                      ] else ...[
                        const Text(
                          'Insufficient funds in wallet to redeem. Please deposit more money.',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ],
                  );
                }
              ),
              actions: [
                TextButton(
                  onPressed: _isProcessing ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                StreamBuilder<double>(
                  stream: _service.getWalletBalanceStream(),
                  builder: (context, snapshot) {
                    final balance = snapshot.data ?? 0.0;
                    final hasEnoughFunds = balance >= totalOwed;
                    
                    return ElevatedButton(
                      onPressed: (_isProcessing || !hasEnoughFunds) ? null : () async {
                        setStateDialog(() => _isProcessing = true);
                        setState(() => _isProcessing = true);
                        
                        try {
                           await _service.redeemAsset(asset: widget.asset, totalOwed: totalOwed);
                           if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Asset Redeemed Successfully!')));
                           }
                        } catch (e) {
                          if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error redeeming asset: $e')));
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
                        : const Text('Confirm Redeem', style: TextStyle(color: Colors.white)),
                    );
                  }
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showSellConfirmation(BuildContext context, double estimatedValue) {
    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
             return AlertDialog(
              title: const Text('Confirm Sale'),
              content: StreamBuilder<double>(
                stream: _service.getWalletBalanceStream(),
                builder: (context, snapshot) {
                  final walletBalance = snapshot.data ?? 0.0;
                  final newBalance = walletBalance + estimatedValue;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Asset: ${widget.asset.name}'),
                      Text('Weight: ${widget.asset.weight} Baht'),
                      const SizedBox(height: 12),
                      const Text('Estimated Value:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('+ ฿ ${estimatedValue.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      const Text('Estimated New Balance:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('฿ ${newBalance.toStringAsFixed(0)}', style: const TextStyle(color: Colors.blue, fontSize: 18, fontWeight: FontWeight.bold)),
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
                    setState(() => _isProcessing = true);
                    
                    try {
                       await _service.sellAsset(asset: widget.asset, sellPrice: estimatedValue);
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

  void _showOwnedAssetOptions(BuildContext context, double currentVal) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(margin: const EdgeInsets.only(top: 8, bottom: 8), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              ListTile(
                leading: const Icon(Icons.storefront, color: Color(0xFF800000)),
                title: const Text('Pick Up Physical Gold In-Store', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Schedule an appointment to collect your gold.'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/appointment', arguments: widget.asset);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.sell, color: Colors.green),
                title: const Text('Sell Digital Gold Asset', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Estimated value: ฿ ${currentVal.toInt()}'),
                onTap: () {
                  Navigator.pop(context);
                  _showSellConfirmation(context, currentVal);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isPawned = widget.asset.status == 'pawned';
    bool isScheduled = widget.asset.status == 'pickup_scheduled';
    double currentVal = widget.asset.weight * (widget.currentRate?.buyPrice ?? 0);
    double profit = currentVal - widget.asset.acquisitionPrice;

    // Pawn Calculations
    double principal = widget.asset.loanAmount ?? 0.0;
    DateTime pawnDate = widget.asset.pawnDate ?? DateTime.now();
    DateTime dueDate = widget.asset.dueDate ?? DateTime.now().add(const Duration(days: 30));
    double rate = widget.asset.interestRate ?? 0.0125;
    
    final owedData = _service.calculatePawnOwed(principal, pawnDate, dueDate, rate);
    double totalOwed = owedData['totalOwed']!;
    double interest = owedData['standardInterest']!;
    double penalty = owedData['penaltyInterest']!;
    
    bool isOverdue = penalty > 0;
    int daysUntilDue = dueDate.difference(DateTime.now()).inDays;
    
    Color pawnColor = isOverdue ? Colors.red : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isPawned ? BorderSide(color: pawnColor, width: 2) : BorderSide.none,
      ),
      child: InkWell(
        onTap: _isProcessing 
           ? null 
           : (isPawned 
               ? () => _showRedeemConfirmation(context, principal, interest, penalty, totalOwed)
               : (isScheduled 
                    ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This asset is locked for a scheduled pickup.')))
                    : () => _showOwnedAssetOptions(context, currentVal))),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isPawned ? pawnColor.withOpacity(0.1) : const Color(0xFFFFF8E1), 
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Icon(
                  isPawned ? (isOverdue ? Icons.warning_amber_rounded : Icons.shield) : Icons.workspace_premium, 
                  color: isPawned ? pawnColor : const Color(0xFF800000),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.asset.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    if (isPawned) ...[
                      if (isOverdue)
                        Text('OVERDUE (${-daysUntilDue} days)', style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold))
                      else
                        Text('Due in $daysUntilDue days', style: const TextStyle(fontSize: 12, color: Colors.orange)),
                    ] else if (isScheduled) ...[
                      const Text('Store Pickup Scheduled', style: TextStyle(fontSize: 12, color: Color(0xFF800000), fontWeight: FontWeight.bold)),
                    ] else
                      Text('${widget.asset.weight} Baht • Acquired ฿ ${widget.asset.acquisitionPrice.toInt()}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (isPawned) ...[
                    const Text('TOTAL OWED', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                    Text('฿ ${totalOwed.toInt()}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: pawnColor)),
                  ] else ...[
                    Text('฿ ${currentVal.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                      '${profit >= 0 ? "+" : ""}฿ ${profit.toInt()}', 
                      style: TextStyle(fontSize: 12, color: profit >= 0 ? Colors.green : Colors.red, fontWeight: FontWeight.bold)
                    ),
                  ],
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
