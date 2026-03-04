import 'package:flutter/material.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      backgroundColor: const Color(0xFFF5F5F7),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 12),
              child: Text(
                'CONTACT US',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening Phone...')));
                    },
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF800000).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.phone, color: Color(0xFF800000)),
                    ),
                    title: const Text('Call Support',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: const Text('+66 2 123 4567',
                        style: TextStyle(fontSize: 13)),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.grey),
                  ),
                  const Divider(
                      height: 1,
                      indent: 64,
                      thickness: 1,
                      color: Color(0xFFF0F0F0)),
                  ListTile(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening LINE...')));
                    },
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06C755).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.chat_bubble,
                          color: Color(0xFF06C755)),
                    ),
                    title: const Text('LINE Official',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: const Text('@sungsengleegold',
                        style: TextStyle(fontSize: 13)),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 12),
              child: Text(
                'FREQUENTLY ASKED QUESTIONS',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: const Column(
                children: [
                  ExpansionTile(
                    title: Text('How do I buy gold online?'),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                            'To buy gold online, navigate to the "Buy / Sell" tab, select "Buy Gold", enter the amount in Baht weight or THB, confirm your transaction limit, and click Buy. Ensure you have sufficient funds in your wallet first.'),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: Text('How do I pick up my gold?'),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                            'You can schedule a pickup from your Profile > My Appointments. Select a date and time slot. When you arrive at the store, show your appointment QR code (or transaction ID) to the staff.'),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: Text('What are your store hours?'),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                            'We are open Monday to Saturday from 9:00 AM to 5:30 PM. We are closed on Sundays and national holidays.'),
                      ),
                    ],
                  ),
                  ExpansionTile(
                    title: Text('How does the pawn system work?'),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                            'If you own gold in your portfolio, you can instantly pawn it through the app for up to 85% of its buyback value. The loan amount is credited straight to your digital wallet with an interest rate of 1.25% per month.'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Padding(
              padding: EdgeInsets.only(left: 8, bottom: 12),
              child: Text(
                'LEGAL',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1.2),
              ),
            ),
             Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                   ListTile(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Terms of Service...')));
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    title: const Text('Terms of Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    trailing: const Icon(Icons.open_in_new, color: Colors.grey, size: 20),
                  ),
                   const Divider(height: 1, indent: 20, thickness: 1, color: Color(0xFFF0F0F0)),
                   ListTile(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Privacy Policy...')));
                    },
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                     title: const Text('Privacy Policy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                     trailing: const Icon(Icons.open_in_new, color: Colors.grey, size: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
