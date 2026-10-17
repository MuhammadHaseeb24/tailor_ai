import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool register = false, loading = false;
  String? error;

  Future<void> submit() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final auth = FirebaseAuth.instance;
      if (register) {
        await auth.createUserWithEmailAndPassword(email: email.text.trim(), password: pass.text);
      } else {
        await auth.signInWithEmailAndPassword(email: email.text.trim(), password: pass.text);
      }
    } on FirebaseAuthException catch (e) {
      error = e.message;
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Aurora(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: C.grad),
                  child: const Icon(Icons.content_cut, size: 44, color: Color(0xFF04101F)),
                ),
                const SizedBox(height: 18),
                const GradientText('TailorAI', size: 36),
                const SizedBox(height: 6),
                const Text('Smart tailor management, AI ke saath',
                    style: TextStyle(color: C.grey)),
                const SizedBox(height: 32),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                      labelText: 'Email', prefixIcon: Icon(Icons.alternate_email)),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: pass,
                  obscureText: true,
                  decoration: const InputDecoration(
                      labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)),
                ),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(error!, style: const TextStyle(color: C.pink)),
                  ),
                const SizedBox(height: 20),
                GradientButton(
                  label: register ? 'Account banayein' : 'Login',
                  icon: Icons.bolt,
                  loading: loading,
                  onPressed: submit,
                ),
                TextButton(
                  onPressed: () => setState(() => register = !register),
                  child: Text(register ? 'Pehle se account hai? Login' : 'Naya account banayein'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
