import 'package:flutter/material.dart';
import '../models/product.dart';

class InquiryPage extends StatefulWidget {
  final Product? product;

  const InquiryPage({super.key, this.product});

  @override
  State<InquiryPage> createState() => _InquiryPageState();
}

class _InquiryPageState extends State<InquiryPage> {
  final _messageController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _messageController.text = 'I am interested in the ${widget.product!.name} (Weight: ${widget.product!.weight}g). Is it available?';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
     if (_messageController.text.isNotEmpty) {
      // In real app, send to API
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message Sent! We will contact you shortly.')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inquiry')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (widget.product != null)
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                color: Colors.amber[50],
                child: ListTile(
                  leading: const Icon(Icons.shopping_bag, color: Colors.amber),
                  title: Text(widget.product!.name),
                  subtitle: Text('฿${widget.product!.price.toStringAsFixed(0)}'),
                ),
              ),
            const Text(
              'How can we help you today?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Type your message here...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Check Availability'),
                  onPressed: () {
                    setState(() {
                      _messageController.text = 'Is this item currently in stock?';
                    });
                  },
                ),
                ActionChip(
                  label: const Text('Request Customization'),
                  onPressed: () {
                     setState(() {
                      _messageController.text = 'I would like to request a custom modification for this item.';
                    });
                  },
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _sendMessage,
              icon: const Icon(Icons.send),
              label: const Text('Send Message'),
               style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
            ),
          ],
        ),
      ),
    );
  }
}
