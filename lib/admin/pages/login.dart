import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import '../providers/admin_provider.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _obscureText = true; // Tambahan fitur agar password bisa diintip secara premium

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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Background ultra clean modern
      appBar: AppBar(
        title: const Text('Admin System Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A), // Warna senada Dashboard Premium
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400), // Batasan lebar agar tetap rapi di Laptop
            padding: const EdgeInsets.all(28.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withOpacity(0.05),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                )
              ],
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🛠️ ICON HEADER UTAMA PREMIUM
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(Icons.lock_person_rounded, color: Color(0xFF1E88E5), size: 28),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Admin Login', 
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5)
                ),
                const SizedBox(height: 6),
                
                // 🛠️ TEKS EASTER EGG ELEGAN (TIDAK ALAY)
                const Text(
                  '"Hanya admin ganteng yang bisa login 😉"', 
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600, fontStyle: FontStyle.italic)
                ),
                const SizedBox(height: 28),
                
                // 🛠️ INPUT EMAIL
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 🛠️ INPUT PASSWORD
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscureText,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    labelText: 'Password Authentication',
                    labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    prefixIcon: const Icon(Icons.lock_outlined, size: 20, color: Color(0xFF94A3B8)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: const Color(0xFF94A3B8)),
                      onPressed: () => setState(() => _obscureText = !_obscureText),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E88E5), width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                
                // 🛠️ CONTAINER ERROR SYSTEM
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!, 
                            style: const TextStyle(color: Color(0xFFDC2626), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                
                // 🛠️ ELEVATED ACTION BUTTON SIGN IN
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signIn,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E3A8A), // Menggunakan Royal Blue gelap premium
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF1E3A8A).withOpacity(0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _loading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                        : const Text('Secure Sign In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.3)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}