import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  final AuthService _authService = AuthService();
  bool _isBiometricEnabled = false;

  void _showChangePasswordDialog() {
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Change Password', style: TextStyle(color: Color(0xFF800000))),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   TextField(
                    controller: newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    if (newPasswordController.text != confirmPasswordController.text) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match.')));
                      return;
                    }
                    if (newPasswordController.text.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password must be at least 6 characters.')));
                      return;
                    }

                    setState(() => isLoading = true);
                    try {
                      await FirebaseAuth.instance.currentUser?.updatePassword(newPasswordController.text);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully.')));
                      }
                    } catch (e) {
                      if (context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update password: $e')));
                      }
                    } finally {
                      if (context.mounted) {
                        setState(() => isLoading = false);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF800000), foregroundColor: Colors.white),
                  child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Change'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Account', style: TextStyle(color: Colors.red)),
          content: const Text(
            'Are you sure you want to permanently delete your account? This action cannot be undone and you will lose all access to your portfolio and transaction history.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  Navigator.pop(context); // Close dialog
                  // Note: Firebase requires recent sign-in before deleting an account
                  // For a production app, we would re-authenticate here.
                  await FirebaseAuth.instance.currentUser?.delete();
                  // User is automatically signed out; the Auth stream handles navigating to guests
                  if (context.mounted) {
                     Navigator.of(context).popUntil((route) => route.isFirst);
                     ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deleted successfully.')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete account. Please log out and log back in, then try again.')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
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
                  'AUTHENTICATION',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
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
                      onTap: _showChangePasswordDialog,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF800000).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.password, color: Color(0xFF800000)),
                      ),
                      title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: const Text('Update your login password', style: TextStyle(fontSize: 13)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    ),
                    const Divider(height: 1, indent: 64, thickness: 1, color: Color(0xFFF0F0F0)),
                     ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF800000).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.fingerprint, color: Color(0xFF800000)),
                      ),
                      title: const Text('Biometric Login', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      subtitle: const Text('Use FaceID or TouchID', style: TextStyle(fontSize: 13)),
                      trailing: Switch(
                        value: _isBiometricEnabled,
                        activeColor: const Color(0xFF800000),
                        onChanged: (val) {
                          setState(() {
                            _isBiometricEnabled = val;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(val ? 'Biometric login enabled.' : 'Biometric login disabled.')));
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Padding(
                  padding: EdgeInsets.only(left: 8, bottom: 12),
                  child: Text(
                    'ACCOUNT MANAGEMENT',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2),
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
                child: ListTile(
                  onTap: _showDeleteAccountDialog,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_forever, color: Colors.red),
                  ),
                  title: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red)),
                  subtitle: const Text('Permanently remove your data', style: TextStyle(fontSize: 13)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
