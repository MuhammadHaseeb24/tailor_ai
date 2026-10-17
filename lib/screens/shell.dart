import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../ai.dart';
import '../data.dart';
import '../ui.dart';
import 'customers.dart';
import 'order_form.dart';
import 'orders.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [Dashboard(), OrdersPage(), CustomersPage(), UdhaarPage()];
    return Scaffold(
      appBar: AppBar(
        title: const GradientText('TailorAI', size: 24),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: Aurora(child: pages[tab]),
      floatingActionButton: (tab == 1 || tab == 2)
          ? FloatingActionButton.extended(
              backgroundColor: C.violet,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: Text(tab == 1 ? 'Naya Order' : 'Naya Customer'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => tab == 1 ? const OrderForm() : const CustomerForm()),
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.space_dashboard_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.content_cut), label: 'Orders'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'Customers'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Udhaar'),
        ],
      ),
    );
  }
}

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final quick = TextEditingController();
  bool busy = false, insightBusy = false;
  String? insight;
  Map<String, dynamic> stats = {};

  void snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> quickOrder() async {
    if (quick.text.trim().isEmpty) return;
    setState(() => busy = true);
    try {
      final parsed = await AiService.parseOrder(quick.text);
      if (!mounted) return;
      quick.clear();
      Navigator.push(context, MaterialPageRoute(builder: (_) => OrderForm(prefill: parsed)));
    } catch (e) {
      if (mounted) snack(errText(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> getInsight() async {
    setState(() => insightBusy = true);
    try {
      final t = await AiService.insights(stats);
      if (mounted) setState(() => insight = t);
    } catch (e) {
      if (mounted) snack(errText(e));
    } finally {
      if (mounted) setState(() => insightBusy = false);
    }
  }

  Widget stat(IconData icon, String value, String label, Color color) => Expanded(
        child: GlassCard(
          margin: const EdgeInsets.all(6),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            Text(label, style: const TextStyle(color: C.grey, fontSize: 12)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: Db.orders.snapshots(),
      builder: (context, snap) {
        final all = (snap.data?.docs ?? []).map((d) => d.data()).toList();
        final active = all.where((o) => o['status'] != 'Delivered').toList();
        final ready = active.where((o) => o['status'] == 'Ready').length;
        final soon = active
            .where((o) =>
                (o['deliveryDate'] as Timestamp).toDate().difference(DateTime.now()).inHours <= 48)
            .length;
        final udhaar = all.fold<double>(0, (s, o) => s + balance(o));
        stats = {
          'activeOrders': active.length,
          'readyForPickup': ready,
          'dueWithin2Days': soon,
          'totalUdhaar': udhaar,
        };

        return ListView(padding: const EdgeInsets.only(bottom: 24), children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: Text('Aaj ka kaam', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(children: [
              Row(children: [
                stat(Icons.content_cut, '${active.length}', 'Active orders', C.violet),
                stat(Icons.check_circle, '$ready', 'Ready for pickup', C.cyan),
              ]),
              Row(children: [
                stat(Icons.timer, '$soon', '48 ghantay mein delivery', C.pink),
                stat(Icons.account_balance_wallet, rs(udhaar), 'Total udhaar', C.green),
              ]),
            ]),
          ),
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.auto_awesome, color: C.cyan),
                SizedBox(width: 8),
                GradientText('AI Quick Order', size: 18),
              ]),
              const SizedBox(height: 6),
              const Text('Bol kar ya likh kar order likhwayein, AI form khud bhar dega.',
                  style: TextStyle(color: C.grey, fontSize: 12)),
              const SizedBox(height: 12),
              TextField(
                controller: quick,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                    hintText: 'Jaise: Ahmed ka 2 suit, Friday tak, total 8000, advance 3000'),
              ),
              const SizedBox(height: 12),
              GradientButton(
                  label: 'AI se order banao',
                  icon: Icons.auto_awesome,
                  loading: busy,
                  onPressed: quickOrder),
            ]),
          ),
          GlassCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.insights, color: C.pink),
                SizedBox(width: 8),
                GradientText('AI Business Insights', size: 18),
              ]),
              const SizedBox(height: 12),
              if (insight != null) ...[
                Text(insight!, style: const TextStyle(height: 1.5)),
                const SizedBox(height: 12),
              ],
              GradientButton(
                  label: insight == null ? 'Meri dukaan ka analysis' : 'Dobara analyze karein',
                  icon: Icons.bolt,
                  loading: insightBusy,
                  onPressed: getInsight),
            ]),
          ),
        ]);
      },
    );
  }
}
