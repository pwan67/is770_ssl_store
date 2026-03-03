import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/gold_rate.dart';
import '../models/gold_transaction.dart';
import '../services/mock_service.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final GoldRate? currentRate;

  const ProductDetailPage({super.key, required this.product, this.currentRate});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final MockService _service = MockService();
  bool _isProcessing = false;

  void _showCheckoutBottomSheet(BuildContext context, double totalPrice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return StreamBuilder<double>(
              stream: _service.getWalletBalanceStream(),
              builder: (context, snapshot) {
                final balance = snapshot.data ?? 0.0;
                final hasEnoughFunds = balance >= totalPrice;

                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 24,
                    right: 24,
                    top: 24,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  const Text('Order Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _summaryRow('Item', widget.product.name),
                  _summaryRow('Weight', '${widget.product.weight} Baht'),
                  _summaryRow('Gold Price', '฿ ${((widget.product.weight * (widget.currentRate?.sellPrice ?? 0))).toStringAsFixed(0)}'),
                  _summaryRow('Labor Fee', '฿ ${widget.product.laborFee.toStringAsFixed(0)}'),
                  const Divider(height: 32),
                  _summaryRow('Total Cost', '฿ ${totalPrice.toStringAsFixed(0)}', isBold: true),
                  if (hasEnoughFunds)
                    _summaryRow('Estimated Remaining Balance', '฿ ${(balance - totalPrice).toStringAsFixed(0)}', isBold: true),
                  const SizedBox(height: 32),
                  if (!hasEnoughFunds)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        'Insufficient funds. Please check your wallet balance.',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ElevatedButton(
                    onPressed: (_isProcessing || !hasEnoughFunds) 
                      ? null 
                      : () async {
                          setModalState(() => _isProcessing = true);
                          try {
                            await _service.createTransaction(
                              assetName: widget.product.name,
                              weight: widget.product.weight,
                              amount: totalPrice,
                              type: TransactionType.buy,
                              category: widget.product.category,
                              productId: widget.product.id,
                            );
                            
                            if (mounted) {
                              Navigator.pop(context); // Close bottom sheet
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Purchase Successful! Added to Portfolio.')),
                              );
                              Navigator.pop(context); // Go back to catalog
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setModalState(() => _isProcessing = false);
                            }
                          }
                        },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: hasEnoughFunds ? const Color(0xFF800000) : Colors.grey,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isProcessing 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Confirm Purchase', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
              }
            );
          }
        );
      },
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double basePrice = widget.currentRate != null ? (widget.product.weight * widget.currentRate!.sellPrice) : 0;
    double totalPrice = basePrice + widget.product.laborFee;
    bool isOutOfStock = widget.product.stock <= 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 350,
              width: double.infinity,
              color: Colors.white,
              child: Image.network(
                widget.product.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Icon(Icons.image, size: 100, color: Colors.grey[400]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.product.name,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isOutOfStock ? Colors.grey[200] : Colors.green[50],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isOutOfStock ? 'Out of Stock' : 'In Stock: ${widget.product.stock}',
                          style: TextStyle(
                            color: isOutOfStock ? Colors.grey[600] : Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${widget.product.weight} Baht',
                        style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                      ),
                      if (widget.currentRate != null)
                        Text(
                          '฿ ${totalPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor),
                        )
                      else
                        const CircularProgressIndicator(),
                    ],
                  ),
                  const Divider(height: 32),
                  const Text('Price Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (widget.currentRate != null) ...[
                    _summaryRow('Current Gold Rate', '฿ ${widget.currentRate!.sellPrice.toStringAsFixed(0)} / Baht'),
                    _summaryRow('Gold Value (${widget.product.weight}x)', '฿ ${basePrice.toStringAsFixed(0)}'),
                    _summaryRow('Labor Fee', '฿ ${widget.product.laborFee.toStringAsFixed(0)}'),
                  ],
                  const SizedBox(height: 24),
                  const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(widget.product.description, style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: isOutOfStock || widget.currentRate == null
                ? null
                : () => _showCheckoutBottomSheet(context, totalPrice),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              backgroundColor: const Color(0xFF800000),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              isOutOfStock ? 'Out of Stock' : 'Buy Now',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
