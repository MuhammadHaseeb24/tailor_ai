import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../ai.dart';
import '../data.dart';
import '../ui.dart';

class OrderForm extends StatefulWidget {
  final Map<String, dynamic>? prefill; // AI Quick Order se
  final String? customerId;
  const OrderForm({super.key, this.prefill, this.customerId});
  @override
  State<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  String? customerId;
  Map<String, dynamic>? customer;
  bool autoTried = false, aiBusy = false;
  final item = TextEditingController();
  final note = TextEditingController();
  final total = TextEditingController();
  final advance = TextEditingController();
  late DateTime date;

  @override
  void initState() {
    super.initState();
    customerId = widget.customerId;
    date = DateTime.now().add(const Duration(days: 7));
    final p = widget.prefill;
    if (p != null) {
      item.text = '${p['item'] ?? ''}';
      note.text = '${p['note'] ?? ''}';
      if (n0(p['total']) > 0) total.text = n0(p['total']).toStringAsFixed(0);
      if (n0(p['advance']) > 0) advance.text = n0(p['advance']).toStringAsFixed(0);
      if (p['deliveryInDays'] is num) {
        date = DateTime.now().add(Duration(days: (p['deliveryInDays'] as num).toInt()));
      }
    }
  }

  void snack(String t) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  String? _match(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final name = '${widget.prefill?['customerName'] ?? ''}'.trim().toLowerCase();
    if (name.isEmpty) return null;
    for (final d in docs) {
      final n = '${d['name']}'.toLowerCase();
      if (n.contains(name) || name.contains(n)) return d.id;
    }
    return null;
  }

  Future<void> ideas() async {
    if (item.text.trim().isEmpty) {
      snack('Pehle kapra / suit likhein');
      return;
    }
    setState(() => aiBusy = true);
    try {
      final t = await AiService.designIdeas(item: item.text, note: note.text);
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: C.card,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const GradientText('AI Design Ideas', size: 18),
            const SizedBox(height: 12),
            Text(t, style: const TextStyle(height: 1.5)),
            const SizedBox(height: 16),
            GradientButton(
              label: 'Note mein add karo',
              icon: Icons.note_add,
              onPressed: () {
                note.text = '${note.text}\n$t'.trim();
                Navigator.pop(ctx);
              },
            ),
          ]),
        ),
      );
    } catch (e) {
      if (mounted) snack(errText(e));
    } finally {
      if (mounted) setState(() => aiBusy = false);
    }
  }

  Future<void> save() async {
    if (customerId == null || customer == null) {
      snack('Customer select karein');
      return;
    }
    if (item.text.trim().isEmpty) {
      snack('Kapra / suit likhein');
      return;
    }
    await Db.orders.add({
      'customerId': customerId,
      'customerName': customer!['name'],
      'phone': customer!['phone'],
      'item': item.text.trim(),
      'note': note.text.trim(),
      'deliveryDate': Timestamp.fromDate(date),
      'total': double.tryParse(total.text) ?? 0,
      'paid': double.tryParse(advance.text) ?? 0,
      'status': 'Cutting',
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final aiName = '${widget.prefill?['customerName'] ?? ''}'.trim();
    return Scaffold(
      appBar: AppBar(title: const Text('Naya Order')),
      body: Aurora(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: Db.customers.orderBy('name').snapshots(),
            builder: (context, snap) {
              final docs = snap.data?.docs ?? [];
              if (docs.isNotEmpty && !autoTried) {
                autoTried = true;
                final id = customerId ?? _match(docs);
                if (id != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    setState(() {
                      customerId = id;
                      customer = docs.firstWhere((d) => d.id == id).data();
                    });
                  });
                }
              }
              return DropdownButtonFormField<String>(
                value: docs.any((d) => d.id == customerId) ? customerId : null,
                dropdownColor: C.card,
                decoration: const InputDecoration(
                    labelText: 'Customer', prefixIcon: Icon(Icons.person_outline)),
                items: docs
                    .map((d) => DropdownMenuItem(value: d.id, child: Text('${d['name']}')))
                    .toList(),
                onChanged: (v) => setState(() {
                  customerId = v;
                  customer = docs.firstWhere((d) => d.id == v).data();
                }),
              );
            },
          ),
          if (customerId == null && aiName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 4),
              child: Text('AI ne naam "$aiName" pakda. Customer select karein ya pehle naya banayein.',
                  style: const TextStyle(color: C.pink, fontSize: 12)),
            ),
          const SizedBox(height: 12),
          TextField(
              controller: item,
              decoration: const InputDecoration(
                  labelText: 'Kapra / Suit (e.g. Shalwar Kameez)',
                  prefixIcon: Icon(Icons.checkroom))),
          const SizedBox(height: 12),
          TextField(
              controller: note,
              minLines: 2,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Design note')),
          const SizedBox(height: 10),
          GradientButton(
              label: 'AI Design Ideas',
              icon: Icons.auto_awesome,
              loading: aiBusy,
              onPressed: ideas),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: TextField(
                  controller: total,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Total (Rs)')),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                  controller: advance,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Advance (Rs)')),
            ),
          ]),
          const SizedBox(height: 12),
          GlassCard(
            margin: EdgeInsets.zero,
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime.now().subtract(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (d != null) setState(() => date = d);
            },
            child: Row(children: [
              const Icon(Icons.calendar_month, color: C.cyan),
              const SizedBox(width: 12),
              Text('Delivery: ${DateFormat('dd MMM yyyy').format(date)}'),
            ]),
          ),
          const SizedBox(height: 22),
          GradientButton(label: 'Order save karein', icon: Icons.check, onPressed: save),
        ]),
      ),
    );
  }
}
