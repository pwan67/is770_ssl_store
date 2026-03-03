import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import '../services/auth_service.dart';
import '03_page_appointment.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authService.user,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;
        if (user != null) {
          return _ProfileMemberView(
            user: user,
            onLogout: () async {
              await _authService.signOut();
            },
          );
        } else {
          return _ProfileGuestView(
            onLoginRequest: () {
              Navigator.pushNamed(context, '/login');
            },
          );
        }
      },
    );
  }
}

// ── Guest View (Landing) ─────────────────────────────────────────────────────
class _ProfileGuestView extends StatelessWidget {
  final VoidCallback onLoginRequest;
  const _ProfileGuestView({required this.onLoginRequest});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Member Services')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.stars, size: 80, color: Color(0xFFFFD700)), // Gold Icon
            const SizedBox(height: 24),
            const Text(
              'Welcome to\nSung Seng Lee Gold',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF800000)),
            ),
            const SizedBox(height: 48),
            
            // Block 1: Existing User
            const Text(
              'Already have an account?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onLoginRequest,
              icon: const Icon(Icons.login),
              label: const Text('Log In'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF800000), // Brand Red
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Log in to view your portfolio and access your transaction history.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            
            const Divider(height: 40),

            // Block 2: New User
            const Text(
              'New to our shop?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onLoginRequest,
              icon: const Icon(Icons.person_add),
              label: const Text('Sign Up'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF800000),
                side: const BorderSide(color: Color(0xFF800000)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
             const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Sign up today to start buying and selling gold from anywhere.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Member View (Profile Form) ───────────────────────────────────────────────
class _ProfileMemberView extends StatefulWidget {
  final User user;
  final VoidCallback onLogout;
  const _ProfileMemberView({required this.user, required this.onLogout});

  @override
  State<_ProfileMemberView> createState() => _ProfileMemberViewState();
}

class _ProfileMemberViewState extends State<_ProfileMemberView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName ?? 'New Member');
    _emailController = TextEditingController(text: widget.user.email);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
            tooltip: 'Logout',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
               Center(
                 child: Column(
                   children: [
                     const CircleAvatar(
                       radius: 50,
                       backgroundColor: Color(0xFFFFF8E1),
                       child: Icon(Icons.account_circle, size: 80, color: Color(0xFF800000)),
                     ),
                     const SizedBox(height: 12),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                       decoration: BoxDecoration(
                         color: const Color(0xFFFFD700),
                         borderRadius: BorderRadius.circular(20),
                       ),
                       child: const Text(
                         'Member Points: 1,250',
                         style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                       ),
                     ),
                   ],
                 ),
               ),
              const SizedBox(height: 32),
              
              const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), prefixIcon: Icon(Icons.email)),
                readOnly: true,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile Updated')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF800000),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Changes'),
              ),
              const SizedBox(height: 32),
              const Text('Store Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: ListTile(
                  leading: const Icon(Icons.calendar_month, color: Color(0xFF800000)),
                  title: const Text('My Appointments', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('View your physical gold pickup schedule'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AppointmentPage()),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
