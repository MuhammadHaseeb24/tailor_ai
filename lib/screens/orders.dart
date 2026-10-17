import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../ai.dart';
import '../data.dart';
import '../ui.dart';

Future<void> sendWhatsApp(String phone, String msg) async {
  var p = phone.replaceAll(RegExp(r'[^0-9]'), '');
  if (p.startsWith('0')) p = '92${p.substring(1)}';
  await launchUrl(Uri.parse('https://wa.me/$p?text=${Uri.encodeComponent(msg)}'),
      mode: LaunchMode.externalApplication);
}

void openOrder(BuildContext context, String id) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: C.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => OrderSheet(id),
    );

// ---------------- ORDERS LIST ----------------
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});
  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  String filter = 'All';

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: ['All', 'Cutting', 'Stitching', 'Ready']
              .map((s) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                    child: ChoiceChip(
                      label: Text(s),
                      selected: filter == s,
                      onSelected: (_) => setState(() => filter = s),
                    ),
                  ))
              .toList(),
        ),
      ),
      Expanded(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: Db.orders.orderBy('deliveryDate').snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs.where((d) {
              final s = d['status'];
              return s != 'Delivered' && (filter == 'All' || s == filter);
            }).toList();
            if (docs.isEmpty) return const EmptyState(Icons.inbox, 'Koi order nahi');
            return ListView(
              padding: const EdgeInsets.only(bottom: 90),
              children: docs.map((d) => OrderTile(d)).toList(),
            );
          },
        ),
      ),
    ]);
  }
}

class OrderTile extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  const OrderTile(this.doc, {super.key});

  @override
  Widget build(BuildContext context) {
    final o = doc.data();
    final bal = balance(o);
    final s = o['status'] as String;
    return GlassCard(
      onTap: () => openOrder(context, doc.id),
      child: Row(children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor(s).withOpacity(.18)),
          child: Icon(statusIcon(s), color: statusColor(s)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${o['customerName']}', style: const TextStyle(fontWeight: FontWeight.w700)),
            Text('${o['item']} • ${fmtDate(o['deliveryDate'])}',
                style: const TextStyle(color: C.grey, fontSize: 12)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(s,
              style: TextStyle(color: statusColor(s), fontWeight: FontWeight.w600, fontSize: 12)),
          if (bal > 0) Text(rs(bal), style: const TextStyle(color: C.pink, fontSize: 12)),
        ]),
      ]),
    );
  }
}

// ---------------- ORDER SHEET ----------------
class OrderSheet extends StatelessWidget {
  final String id;
  const OrderSheet(this.id, {super.key});

  Future<void> addPayment(BuildContext context) async {
    final c = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Payment lein'),
        content: TextField(
          controller: c,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Raqam (Rs)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, double.tryParse(c.text)),
              child: const Text('Save')),
        ],
      ),
    );
    if (amount != null && amount > 0) {
      await Db.orders.doc(id).update({'paid': FieldValue.increment(amount)});
    }
  }

  Future<void> delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Order delete karein?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Nahi')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Haan')),
        ],
      ),
    );
    if (ok == true) {
      await Db.orders.doc(id).delete();
      if (context.mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: Db.orders.doc(id).snapshots(),
      builder: (context, snap) {
        final o = snap.data?.data();
        if (o == null) {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        }
        final bal = balance(o);
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text('${o['customerName']} - ${o['item']}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              IconButton(
                  icon: const Icon(Icons.delete_outline, color: C.pink),
                  onPressed: () => delete(context)),
            ]),
            Text('Delivery: ${fmtDate(o['deliveryDate'])}', style: const TextStyle(color: C.grey)),
            if ('${o['note'] ?? ''}'.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Note: ${o['note']}'),
            ],
            const SizedBox(height: 12),
            Text('Total ${rs(n0(o['total']))}   •   Paid ${rs(n0(o['paid']))}   •   Baqaya ${rs(bal)}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              children: statuses
                  .map((s) => ChoiceChip(
                        label: Text(s),
                        selected: o['status'] == s,
                        onSelected: (_) => Db.orders.doc(id).update({'status': s}),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.payments),
                  label: const Text('Payment'),
                  onPressed: () => addPayment(context),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GradientButton(
                  label: 'AI WhatsApp',
                  icon: Icons.auto_awesome,
                  onPressed: () =>
                      showDialog(context: context, builder: (_) => MessageDialog(o)),
                ),
              ),
            ]),
          ]),
        );
      },
    );
  }
}

// ---------------- AI MESSAGE ----------------
class MessageDialog extends StatefulWidget {
  final Map<String, dynamic> order;
  const MessageDialog(this.order, {super.key});
  @override
  State<MessageDialog> createState() => _MessageDialogState();
}

class _MessageDialogState extends State<MessageDialog> {
  String lang = 'Roman Urdu', tone = 'Respectful';
  final ctrl = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    generate();
  }

  Future<void> generate() async {
    final o = widget.order;
    final bal = balance(o);
    final s = '${o['status']}';
    setState(() => loading = true);
    try {
      ctrl.text = await AiService.message(
        name: '${o['customerName']}',
        item: '${o['item']}',
        balance: bal,
        purpose: s == 'Ready'
            ? 'order is ready for pickup'
            : bal > 0
                ? 'friendly payment reminder'
                : 'order progress update (status: $s)',
        language: lang,
        tone: tone,
      );
    } catch (_) {
      // AI na chale to simple template
      ctrl.text = 'Assalam o Alaikum ${o['customerName']}, aap ka ${o['item']} '
          '${s == 'Ready' ? 'tayyar hai' : 'ka kaam jaari hai'}.'
          '${bal > 0 ? ' Baqaya raqam: ${rs(bal)}.' : ''} Shukriya!';
    }
    if (mounted) setState(() => loading = false);
  }

  Widget chips(List<String> items, String value, ValueChanged<String> onPick) => Wrap(
        spacing: 8,
        children: items
            .map((s) => ChoiceChip(
                  label: Text(s),
                  selected: value == s,
                  onSelected: (_) {
                    onPick(s);
                    generate();
                  },
                ))
            .toList(),
      );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(children: [
        Icon(Icons.auto_awesome, color: C.cyan),
        SizedBox(width: 8),
        Text('AI Message'),
      ]),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          chips(['Roman Urdu', 'Urdu', 'English'], lang, (v) => setState(() => lang = v)),
          const SizedBox(height: 4),
          chips(['Respectful', 'Friendly'], tone, (v) => setState(() => tone = v)),
          const SizedBox(height: 12),
          if (loading) const LinearProgressIndicator(),
          TextField(controller: ctrl, minLines: 3, maxLines: 6, enabled: !loading),
        ]),
      ),
      actions: [
        TextButton(onPressed: loading ? null : generate, child: const Text('Dobara')),
        FilledButton.icon(
          icon: const Icon(Icons.send),
          label: const Text('WhatsApp'),
          onPressed: loading
              ? null
              : () => sendWhatsApp('${widget.order['phone']}', ctrl.text),
        ),
      ],
    );
  }
}

// ---------------- UDHAAR ----------------
class UdhaarPage extends StatelessWidget {
  const UdhaarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: Db.orders.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs.where((d) => balance(d.data()) > 0).toList()
          ..sort((a, b) => balance(b.data()).compareTo(balance(a.data())));
        final sum = docs.fold<double>(0, (s, d) => s + balance(d.data()));
        return Column(children: [
          GlassCard(
            child: Row(children: [
              const Icon(Icons.account_balance_wallet, color: C.green, size: 32),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total baqaya', style: TextStyle(color: C.grey)),
                GradientText(rs(sum), size: 26),
              ]),
            ]),
          ),
          Expanded(
            child: docs.isEmpty
                ? const EmptyState(Icons.celebration, 'Koi udhaar baqi nahi')
                : ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: docs.map((d) {
                      final o = d.data();
                      return GlassCard(
                        onTap: () => openOrder(context, d.id),
                        child: Row(children: [
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('${o['customerName']}',
                                  style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text('${o['item']}',
                                  style: const TextStyle(color: C.grey, fontSize: 12)),
                            ]),
                          ),
                          Text(rs(balance(o)),
                              style: const TextStyle(
                                  color: C.pink, fontWeight: FontWeight.w800, fontSize: 16)),
                        ]),
                      );
                    }).toList(),
                  ),
          ),
        ]);
      },
    );
  }
}
