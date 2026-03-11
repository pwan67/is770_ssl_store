import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'owner/owner_overview_tab.dart';
import 'owner/owner_inventory_tab.dart';
import 'owner/owner_ledger_tab.dart';
import 'owner/owner_pickups_tab.dart';

class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const OwnerOverviewTab(),
    const OwnerInventoryTab(),
    const OwnerLedgerTab(),
    const OwnerPickupsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Owner Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: const Color(0xFF800000), // Maroon theme
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.request_page),
            label: 'Ledger',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Pickups',
          ),
        ],
      ),
    );
  }
}
