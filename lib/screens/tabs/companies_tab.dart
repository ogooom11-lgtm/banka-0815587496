import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bank_provider.dart';
import '../../widgets/common.dart';

class CompaniesTab extends StatelessWidget {
  const CompaniesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final cur = bank.currency;

    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: bank.companies.length,
        itemBuilder: (context, i) {
          final c = bank.companies[i];
          final empCount = bank.usersOfCompany(c.id).length;
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.indigo.withOpacity(0.2),
                child: const Icon(Icons.business, color: Colors.indigo),
              ),
              title: Text(c.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('$empCount çalışan'),
                  Text(money(c.balance, cur),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: c.balance > 0 ? Colors.green : Colors.red,
                      )),
                ],
              ),
              trailing: Wrap(
                spacing: 4,
                children: [
                  IconButton(
                    icon: const Icon(Icons.account_balance_wallet),
                    tooltip: 'Bakiye Yükle/Düş',
                    onPressed: () => _showBalanceDialog(context, c.id, c.name),
                  ),
                  IconButton(
                    icon: const Icon(Icons.receipt_long),
                    tooltip: 'İşlem Geçmişi',
                    onPressed: () => _showCompanyTxns(context, c.id, c.name),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Şirketi Sil',
                    onPressed: () => showConfirmDialog(
                      context,
                      title: 'Şirketi Sil',
                      message:
                          '${c.name} silinecek. Çalışanlar da etkilenecek. Emin misiniz?',
                      onConfirm: () {
                        bank.deleteCompany(c.id);
                        showSnackBar(context, 'Şirket silindi.');
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Yeni Şirket'),
        onPressed: () => _showAddDialog(context),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final balCtrl = TextEditingController(text: '100000');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Şirket'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                  labelText: 'Şirket Adı', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: balCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                  labelText: 'Başlangıç Kredisi (${context.read<BankProvider>().currency})',
                  border: const OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal')),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final bal = double.tryParse(balCtrl.text) ?? 0;
              if (name.isEmpty) return;
              context.read<BankProvider>().addCompany(name, bal);
              Navigator.pop(ctx);
              showSnackBar(context, 'Şirket oluşturuldu.');
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  void _showBalanceDialog(BuildContext context, String id, String name) {
    final ctrl = TextEditingController();
    final reasonCtrl = TextEditingController(text: 'Manuel bakiye güncelleme');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$name - Bakiye Güncelle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(signed: true),
              decoration: InputDecoration(
                labelText:
                    'Yeni bakiye (${context.read<BankProvider>().currency})',
                hintText: 'Pozitif=yükle, Negatif=düş',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                  labelText: 'Açıklama', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal')),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text);
              if (v == null) return;
              context
                  .read<BankProvider>()
                  .updateCompanyBalance(id, v, reasonCtrl.text);
              Navigator.pop(ctx);
              showSnackBar(context, 'Bakiye güncellendi.');
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showCompanyTxns(BuildContext context, String id, String name) {
    final bank = context.read<BankProvider>();
    final txns = bank.txnsOfCompany(id);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        builder: (ctx, scroll) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('$name - İşlemler',
                  style: Theme.of(ctx).textTheme.titleLarge),
            ),
            const Divider(),
            Expanded(
              child: txns.isEmpty
                  ? const Center(child: Text('İşlem yok'))
                  : ListView.builder(
                      controller: scroll,
                      itemCount: txns.length,
                      itemBuilder: (c, i) {
                        final t = txns[i];
                        return ListTile(
                          leading: Icon(TxnIcon.of(t.type),
                              color: TxnIcon.colorOf(t.type)),
                          title: Text(t.type.label),
                          subtitle: Text(t.description),
                          trailing: Text(money(t.amount, bank.currency)),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
