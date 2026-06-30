import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import '../providers/admin_provider.dart';
// Test mode flag removed - no external main import needed

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailCtrl = TextEditingController(text: "labiniofficialsurabaya@gmail.com");
  final _passCtrl = TextEditingController(text: "oyar021001");
  bool _loading = false;
  String? _error;

  Future<void> _signIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      debugPrint("INFO: Mencoba login untuk email: ${_emailCtrl.text.trim()}");
      
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      
      if (mounted) {
        debugPrint("INFO: Login Sukses!");
        Provider.of<AdminProvider>(context, listen: false).startListening();
        Navigator.of(context).pushReplacementNamed('/admin');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("ERROR_FIREBASE_CODE: ${e.code}");
      debugPrint("ERROR_FIREBASE_MSG: ${e.message}");
      setState(() { 
        _error = "Firebase Error [${e.code}]: ${e.message}"; 
      });
    } catch (e) {
      debugPrint("ERROR_SISTEM_UMUM: $e");
      setState(() { 
        _error = "Sistem Error: ${e.toString()}"; 
      });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  // Anonymous and test login removed to restrict admin access to email/password only

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Admin Login', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            if (_error != null) 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _error!, 
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _signIn,
                child: _loading 
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Sign in (Firebase)'),
              ),
            ),
            // Anonymous and test login buttons removed
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Test Credentials (for development):',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const Text(
              'Email: labiniofficialsurabaya@gmail.com\nPassword: oyar021001',
              style: TextStyle(fontSize: 10, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}