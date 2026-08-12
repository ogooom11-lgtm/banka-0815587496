import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/bank_provider.dart';
import '../models/app_user.dart';
import '../widgets/common.dart';

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  final _transferCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String? _targetUserId;

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final u = bank.currentUser!;
    final company = bank.companyById(u.companyId);
    final txns = bank.txnsOfUser(u.id);
    final cur = bank.currency;
    final daysLeft = u.contractEnd.difference(DateTime.now()).inDays;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.account_balance_wallet),
            const SizedBox(width: 8),
            Text(bank.bankName),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => bank.logout()),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Provider otomatik rebuild eder; kısa bir gecikme ile UX göster
          await Future.delayed(const Duration(milliseconds: 300));
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Karşılama
              Card(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primaryContainer,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Merhaba, ${u.fullName}',
                          style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('${u.title} • ${company?.name ?? "—"}',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.85))),
                      const SizedBox(height: 20),
                      const Text('Mevcut Bakiye',
                          style: TextStyle(
                              color: Colors.white70, fontSize: 13)),
                      Text(
                        money(u.balance, cur),
                        style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Hızlı bilgiler
              LayoutBuilder(builder: (context, c) {
                final count = c.maxWidth > 700 ? 3 : 1;
                return GridView.count(
                  crossAxisCount: count,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                  children: [
                    StatCard(
                      title: 'Aylık Maaş',
                      value: money(u.salary, cur),
                      icon: Icons.payments,
                      color: Colors.green,
                    ),
                    StatCard(
                      title: 'Aylık Prim',
                      value: money(u.bonus, cur),
                      icon: Icons.card_giftcard,
                      color: Colors.purple,
                    ),
                    StatCard(
                      title: 'Sözleşme',
                      value: daysLeft > 0 ? '$daysLeft gün' : 'Süre doldu',
                      icon: Icons.description,
                      color: daysLeft > 0 ? Colors.blue : Colors.orange,
                      subtitle:
                          'Bitiş: ${DateFormat('dd.MM.yyyy').format(u.contractEnd)}',
                    ),
                  ],
                );
              }),

              const SizedBox(height: 24),
              Text('Para Transferi',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        value: _targetUserId,
                        decoration: const InputDecoration(
                          labelText: 'Alıcı',
                          border: OutlineInputBorder(),
                        ),
                        items: bank.users
                            .where((x) => x.id != u.id)
                            .map((x) => DropdownMenuItem(
                                value: x.id,
                                child: Text(
                                    '${x.fullName} (${x.email})')))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _targetUserId = v),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _transferCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Tutar ($cur)',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _noteCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Açıklama',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.send),
                          label: const Text('Gönder'),
                          onPressed: _sendTransfer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              Text('İşlem Geçmişi',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              Card(
                child: txns.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: Text('Henüz işlem yok.')),
                      )
                    : Column(
                        children: txns.map((t) {
                          final isIn = t.toId == u.id;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: TxnIcon.colorOf(t.type)
                                  .withOpacity(0.15),
                              child: Icon(TxnIcon.of(t.type),
                                  color: TxnIcon.colorOf(t.type),
                                  size: 18),
                            ),
                            title: Text(t.type.label),
                            subtitle: Text(
                                '${t.description}\n${DateFormat('dd.MM.yyyy HH:mm').format(t.date)}'),
                            isThreeLine: true,
                            trailing: Text(
                              '${isIn ? '+' : '-'}${money(t.amount, cur)}',
                              style: TextStyle(
                                color: isIn ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _sendTransfer() {
    final bank = context.read<BankProvider>();
    final amount = double.tryParse(_transferCtrl.text);
    if (amount == null || amount <= 0) {
      showSnackBar(context, 'Geçerli bir tutar girin.', error: true);
      return;
    }
    if (_targetUserId == null) {
      showSnackBar(context, 'Alıcı seçin.', error: true);
      return;
    }
    try {
      bank.userTransfer(bank.currentUser!.id, _targetUserId!, amount,
          _noteCtrl.text.isEmpty ? 'Transfer' : _noteCtrl.text);
      _transferCtrl.clear();
      _noteCtrl.clear();
      setState(() => _targetUserId = null);
      showSnackBar(context, 'Transfer başarılı.');
    } catch (e) {
      showSnackBar(context, e.toString(), error: true);
    }
  }
}
