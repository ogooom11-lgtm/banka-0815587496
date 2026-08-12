import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/bank_provider.dart';
import '../../models/transaction.dart';
import '../../widgets/common.dart';

class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  TxnType? _filter;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    var txns = bank.transactions;
    if (_filter != null) {
      txns = txns.where((t) => t.type == _filter).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      txns = txns
          .where((t) =>
              t.description.toLowerCase().contains(q) ||
              t.type.label.toLowerCase().contains(q))
          .toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'İşlem ara...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: const Text('Tümü'),
                        selected: _filter == null,
                        onSelected: (_) => setState(() => _filter = null),
                      ),
                    ),
                    for (final t in TxnType.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(t.label),
                          selected: _filter == t,
                          onSelected: (_) => setState(() => _filter = t),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: txns.isEmpty
              ? const Center(child: Text('İşlem bulunamadı.'))
              : ListView.builder(
                  itemCount: txns.length,
                  itemBuilder: (context, i) {
                    final t = txns[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                            TxnIcon.colorOf(t.type).withOpacity(0.15),
                        child: Icon(TxnIcon.of(t.type),
                            color: TxnIcon.colorOf(t.type), size: 20),
                      ),
                      title: Text(t.type.label),
                      subtitle: Text(
                        '${t.description}\n${DateFormat('dd.MM.yyyy HH:mm').format(t.date)}',
                      ),
                      isThreeLine: true,
                      trailing: Text(
                        money(t.amount, bank.currency),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: TxnIcon.colorOf(t.type),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
