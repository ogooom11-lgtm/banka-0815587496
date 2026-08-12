import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bank_provider.dart';
import '../../widgets/common.dart';

class OverviewTab extends StatelessWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final cur = bank.currency;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Genel Bakış',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Toplam ${bank.companies.length} şirket, ${bank.users.where((u) => u.role == UserRole.employee).length} çalışan',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          LayoutBuilder(builder: (context, c) {
            final count = c.maxWidth > 800 ? 4 : (c.maxWidth > 500 ? 2 : 1);
            return GridView.count(
              crossAxisCount: count,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.6,
              children: [
                StatCard(
                  title: 'Toplam Şirket Bakiyesi',
                  value: money(bank.totalCompanyBalance, cur),
                  icon: Icons.business,
                  color: Colors.indigo,
                ),
                StatCard(
                  title: 'Toplam Kullanıcı Bakiyesi',
                  value: money(bank.totalUserBalance, cur),
                  icon: Icons.people,
                  color: Colors.teal,
                ),
                StatCard(
                  title: 'Aylık Toplam Maaş',
                  value: money(bank.totalMonthlySalaries, cur),
                  icon: Icons.payments,
                  color: Colors.green,
                ),
                StatCard(
                  title: 'Toplam İşlem',
                  value: bank.transactions.length.toString(),
                  icon: Icons.receipt_long,
                  color: Colors.orange,
                ),
              ],
            );
          }),
          const SizedBox(height: 24),
          Text('Hızlı İşlemler',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ActionChip(
                avatar: const Icon(Icons.payments, size: 18),
                label: const Text('Vadesi Gelen Maaşları Öde'),
                onPressed: () {
                  final n = bank.processDueSalaries();
                  showSnackBar(context, '$n maaş ödemesi yapıldı.');
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.casino, size: 18),
                label: const Text('Rastgele Kesinti Uygula'),
                onPressed: () {
                  final n = bank.applyRandomDeductionsToAll();
                  showSnackBar(context, '$n kullanıcıya kesinti yapıldı.');
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Son İşlemler',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: bank.transactions.take(10).map((t) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        TxnIcon.colorOf(t.type).withOpacity(0.2),
                    child: Icon(TxnIcon.of(t.type),
                        color: TxnIcon.colorOf(t.type), size: 20),
                  ),
                  title: Text(t.type.label),
                  subtitle: Text(t.description),
                  trailing: Text(
                    '${t.type == TxnType.penalty || t.type == TxnType.randomDeduction || t.type == TxnType.terminationFee ? '-' : '+'}${money(t.amount, cur)}',
                    style: TextStyle(
                      color: TxnIcon.colorOf(t.type),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
