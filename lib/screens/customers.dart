import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ai.dart';
import '../data.dart';
import '../ui.dart';
import 'order_form.dart';
import 'orders.dart';

// ---------------- LIST ----------------
class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});
  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: TextField(
          onChanged: (v) => setState(() => q = v.toLowerCase()),
          decoration: const InputDecoration(
              hintText: 'Naam ya phone se dhoondein', prefixIcon: Icon(Icons.search)),
        ),
      ),
      Expanded(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: Db.customers.orderBy('name').snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs
                .where((d) =>
                    '${d['name']}'.toLowerCase().contains(q) || '${d['phone']}'.contains(q))
                .toList();
            if (docs.isEmpty) return const EmptyState(Icons.people_outline, 'Koi customer nahi');
            return ListView(
              padding: const EdgeInsets.only(bottom: 90),
              children: docs.map((d) {
                final name = '${d['name']}';
                return GlassCard(
                  onTap: () => Navigator.push(
                      context, MaterialPageRoute(builder: (_) => CustomerDetail(d.id))),
                  child: Row(children: [
                    CircleAvatar(
                      backgroundColor: C.violet,
                      child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('${d['phone']}', style: const TextStyle(color: C.grey, fontSize: 12)),
                      ]),
                    ),
                    const Icon(Icons.chevron_right, color: C.grey),
                  ]),
                );
              }).toList(),
            );
          },
        ),
      ),
    ]);
  }
}

// ---------------- DETAIL ----------------
class CustomerDetail extends StatelessWidget {
  final String id;
  const CustomerDetail(this.id, {super.key});

  Future<void> delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Customer delete karein?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Nahi')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Haan')),
        ],
      ),
    );
    if (ok == true) {
      if (context.mounted) Navigator.pop(context);
      await Db.customers.doc(id).delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: Db.customers.doc(id).snapshots(),
      builder: (context, snap) {
        final c = snap.data?.data();
        if (c == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final m = Map<String, dynamic>.from(c['measurements'] ?? {});
        final w = (MediaQuery.of(context).size.width - 80) / 2;
        return Scaffold(
          appBar: AppBar(
            title: Text('${c['name']}'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CustomerForm(id: id, existing: c))),
              ),
              IconButton(
                  icon: const Icon(Icons.delete_outline, color: C.pink),
                  onPressed: () => delete(context)),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: C.violet,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Naya Order'),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => OrderForm(customerId: id))),
          ),
          body: Aurora(
            child: ListView(padding: const EdgeInsets.only(bottom: 90), children: [
              GlassCard(
                child: Row(children: [
                  Expanded(
                    child: Text('${c['phone']}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.call, color: C.green),
                    onPressed: () => launchUrl(Uri.parse('tel:${c['phone']}')),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat, color: C.cyan),
                    onPressed: () => sendWhatsApp('${c['phone']}', 'Assalam o Alaikum ${c['name']}'),
                  ),
                ]),
              ),
              GlassCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const GradientText('Naap (inches)', size: 16),
                  const SizedBox(height: 12),
                  Wrap(
                    runSpacing: 10,
                    children: mFields
                        .map((f) => SizedBox(
                              width: w,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(f, style: const TextStyle(color: C.grey, fontSize: 12)),
                                Text(m[f] == null || '${m[f]}'.isEmpty ? '-' : '${m[f]}',
                                    style: const TextStyle(
                                        fontSize: 18, fontWeight: FontWeight.w700)),
                              ]),
                            ))
                        .toList(),
                  ),
                ]),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 14, 20, 4),
                child: Text('Order history', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: Db.orders.where('customerId', isEqualTo: id).snapshots(),
                builder: (context, s) {
                  final docs = s.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Abhi koi order nahi', style: TextStyle(color: C.grey)),
                    );
                  }
                  return Column(children: docs.map((d) => OrderTile(d)).toList());
                },
              ),
            ]),
          ),
        );
      },
    );
  }
}

// ---------------- FORM ----------------
class CustomerForm extends StatefulWidget {
  final String? id;
  final Map<String, dynamic>? existing;
  const CustomerForm({super.key, this.id, this.existing});
  @override
  State<CustomerForm> createState() => _CustomerFormState();
}

class _CustomerFormState extends State<CustomerForm> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final aiText = TextEditingController();
  final m = {for (final f in mFields) f: TextEditingController()};
  bool aiBusy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      name.text = '${e['name']}';
      phone.text = '${e['phone']}';
      final meas = Map<String, dynamic>.from(e['measurements'] ?? {});
      for (final f in mFields) {
        m[f]!.text = '${meas[f] ?? ''}';
      }
    }
  }

  void snack(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> aiFill() async {
    if (aiText.text.trim().isEmpty) return;
    setState(() => aiBusy = true);
    try {
      final r = await AiService.parseMeasurements(aiText.text, mFields);
      setState(() {
        for (final f in mFields) {
          if (r[f]!.isNotEmpty) m[f]!.text = r[f]!;
        }
      });
    } catch (e) {
      if (mounted) snack(errText(e));
    } finally {
      if (mounted) setState(() => aiBusy = false);
    }
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty || phone.text.trim().isEmpty) {
      snack('Naam aur phone zaroori hain');
      return;
    }
    final data = {
      'name': name.text.trim(),
      'phone': phone.text.trim(),
      'measurements': {for (final f in mFields) f: m[f]!.text.trim()},
    };
    if (widget.id == null) {
      await Db.customers.add({...data, 'createdAt': FieldValue.serverTimestamp()});
    } else {
      await Db.customers.doc(widget.id).update(data);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final w = (MediaQuery.of(context).size.width - 44) / 2;
    return Scaffold(
      appBar: AppBar(title: Text(widget.id == null ? 'Naya Customer' : 'Customer edit')),
      body: Aurora(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(
              controller: name,
              decoration: const InputDecoration(
                  labelText: 'Naam', prefixIcon: Icon(Icons.person_outline))),
          const SizedBox(height: 12),
          TextField(
              controller: phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Phone (03xx...)', prefixIcon: Icon(Icons.phone_outlined))),
          const SizedBox(height: 16),
          GlassCard(
            margin: EdgeInsets.zero,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Icon(Icons.auto_awesome, color: C.cyan),
                SizedBox(width: 8),
                GradientText('AI Naap Assistant', size: 16),
              ]),
              const SizedBox(height: 4),
              const Text('Keyboard ke mic se bol kar bhi likh sakte hain.',
                  style: TextStyle(color: C.grey, fontSize: 12)),
              const SizedBox(height: 10),
              TextField(
                controller: aiText,
                minLines: 2,
                maxLines: 3,
                decoration: const InputDecoration(
                    hintText: 'Jaise: chest 40, kamar 34, lambai 42, aasteen 24'),
              ),
              const SizedBox(height: 10),
              GradientButton(
                  label: 'Naap khud bharo',
                  icon: Icons.auto_awesome,
                  loading: aiBusy,
                  onPressed: aiFill),
            ]),
          ),
          const SizedBox(height: 16),
          const Text('Naap (inches)', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: mFields
                .map((f) => SizedBox(
                      width: w,
                      child: TextField(
                        controller: m[f],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: f),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 22),
          GradientButton(label: 'Save', icon: Icons.check, onPressed: save),
        ]),
      ),
    );
  }
}
