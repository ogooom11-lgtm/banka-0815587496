import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/bank_provider.dart';
import '../../widgets/common.dart';

class CompaniesTab extends StatelessWidget {
  const CompaniesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final cur = bank.currency;

    return Scaffold(
      body: bank.companies.isEmpty
          ? const Center(
              child: Text(
                'Henüz kayıtlı şirket bulunmuyor.\n"Yeni Şirket" butonuyla ekleyebilirsiniz.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: bank.companies.length,
              itemBuilder: (context, i) {
                final c = bank.companies[i];
                final employees = bank.usersOfCompany(c.id);
                final empCount = employees.length;
                final activeEmpCount =
                    employees.where((e) => e.isActive).length;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.indigo.withAlpha(51),
                      child: const Icon(Icons.business,
                          color: Colors.indigo, size: 28),
                    ),
                    title: Text(
                      c.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '$empCount çalışan ($activeEmpCount aktif)',
                          style: const TextStyle(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          money(c.balance, cur),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: c.balance >= 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.account_balance_wallet_outlined),
                          tooltip: 'Bakiye İşlemleri (Yükle / Düş)',
                          onPressed: () =>
                              _showBalanceDialog(context, c.id, c.name, c.balance),
                        ),
                        IconButton(
                          icon: const Icon(Icons.receipt_long_outlined),
                          tooltip: 'Şirket İşlem Geçmişi',
                          onPressed: () =>
                              _showCompanyTxns(context, c.id, c.name),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: 'Şirketi Sil',
                          onPressed: () => showConfirmDialog(
                            context,
                            title: 'Şirketi Sil',
                            message:
                                '"${c.name}" şirketi sistemden silinecek. Bağlı çalışanlar boşa çıkarılacaktır. Devam etmek istiyor musunuz?',
                            confirmText: 'Şirketi Sil',
                            confirmColor: Colors.red,
                            onConfirm: () {
                              bank.deleteCompany(c.id);
                              showSnackBar(context, '"${c.name}" şirketi silindi.');
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
        icon: const Icon(Icons.add_business),
        label: const Text('Yeni Şirket'),
        onPressed: () => _showAddDialog(context),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final balCtrl = TextEditingController(text: '100000');
    final cur = context.read<BankProvider>().currency;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Şirket Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Şirket Adı',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: balCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Başlangıç Kredisi ($cur)',
                prefixIcon: const Icon(Icons.attach_money),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final rawBal = balCtrl.text.trim().replaceAll(',', '.');
              final bal = double.tryParse(rawBal);

              if (name.isEmpty) {
                showSnackBar(context, 'Şirket adı boş bırakılamaz.',
                    error: true);
                return;
              }
              if (bal == null || bal < 0) {
                showSnackBar(context, 'Geçerli bir başlangıç bakiyesi girin.',
                    error: true);
                return;
              }

              try {
                context.read<BankProvider>().addCompany(name, bal);
                Navigator.pop(ctx);
                showSnackBar(context, '"$name" şirketi oluşturuldu.');
              } catch (e) {
                showSnackBar(context, e.toString().replaceAll('Exception: ', ''),
                    error: true);
              }
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  void _showBalanceDialog(
      BuildContext context, String id, String name, double currentBalance) {
    int mode = 0; // 0: Kredi Yükle (+), 1: Bakiye Düş (-), 2: Yeni Bakiye Belirle
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final cur = context.read<BankProvider>().currency;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('$name - Bakiye İşlemi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(ctx).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Mevcut Bakiye:',
                          style: TextStyle(fontSize: 13)),
                      Text(
                        money(currentBalance, cur),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Yükle (+)')),
                    ButtonSegment(value: 1, label: Text('Düş (-)')),
                    ButtonSegment(value: 2, label: Text('Belirle')),
                  ],
                  selected: {mode},
                  onSelectionChanged: (val) =>
                      setS(() => mode = val.first),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  autofocus: true,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: mode == 0
                        ? 'Yüklenecek Tutar ($cur)'
                        : (mode == 1
                            ? 'Düşülecek Tutar ($cur)'
                            : 'Yeni Bakiye Tutarı ($cur)'),
                    prefixIcon: const Icon(Icons.attach_money),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'İşlem Açıklaması (opsiyonel)',
                    prefixIcon: Icon(Icons.notes),
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                final raw = amountCtrl.text.trim().replaceAll(',', '.');
                final val = double.tryParse(raw);
                if (val == null || val < 0) {
                  showSnackBar(context, 'Geçerli bir tutar girin.',
                      error: true);
                  return;
                }

                final bank = context.read<BankProvider>();
                try {
                  if (mode == 0) {
                    if (val == 0) return;
                    bank.depositToCompany(
                      id,
                      val,
                      reasonCtrl.text.isEmpty
                          ? 'Banka tarafından kredi yüklendi'
                          : reasonCtrl.text,
                    );
                    showSnackBar(context,
                        '$name şirketine ${money(val, cur)} yüklendi.');
                  } else if (mode == 1) {
                    if (val == 0) return;
                    bank.withdrawFromCompany(
                      id,
                      val,
                      reasonCtrl.text.isEmpty
                          ? 'Banka tarafından bakiye düşüldü'
                          : reasonCtrl.text,
                    );
                    showSnackBar(context,
                        '$name şirketinden ${money(val, cur)} düşüldü.');
                  } else {
                    bank.updateCompanyBalance(
                      id,
                      val,
                      reasonCtrl.text.isEmpty
                          ? 'Bakiye güncellendi'
                          : reasonCtrl.text,
                    );
                    showSnackBar(context,
                        '$name şirketinin yeni bakiyesi: ${money(val, cur)}');
                  }
                  Navigator.pop(ctx);
                } catch (e) {
                  showSnackBar(
                      context, e.toString().replaceAll('Exception: ', ''),
                      error: true);
                }
              },
              child: const Text('Uygula'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompanyTxns(BuildContext context, String id, String name) {
    final bank = context.read<BankProvider>();
    final txns = bank.txnsOfCompany(id);
    final cur = bank.currency;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (ctx, scroll) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.business, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$name - İşlem Geçmişi',
                      style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: txns.isEmpty
                  ? const Center(
                      child: Text(
                        'Bu şirkete ait kayıtlı bir işlem bulunmuyor.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      controller: scroll,
                      itemCount: txns.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (c, i) {
                        final t = txns[i];
                        final isIncoming = t.toId == id && t.fromId != id;
                        final isZero = t.amount == 0;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                TxnIcon.colorOf(t.type).withAlpha(38),
                            child: Icon(
                              TxnIcon.of(t.type),
                              color: TxnIcon.colorOf(t.type),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            t.type.label,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${t.description}\n${DateFormat('dd.MM.yyyy HH:mm').format(t.date)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          isThreeLine: true,
                          trailing: Text(
                            isZero
                                ? money(0, cur)
                                : '${isIncoming ? '+' : '-'}${money(t.amount, cur)}',
                            style: TextStyle(
                              color: isZero
                                  ? Colors.grey
                                  : (isIncoming ? Colors.green : Colors.red),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
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
