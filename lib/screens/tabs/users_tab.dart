import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/bank_provider.dart';
import '../../models/app_user.dart';
import '../../widgets/common.dart';

class UsersTab extends StatelessWidget {
  const UsersTab({super.key});

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final employees =
        bank.users.where((u) => u.role != UserRole.superAdmin).toList();

    return Scaffold(
      body: employees.isEmpty
          ? const Center(child: Text('Henüz kullanıcı yok.'))
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: employees.length,
              itemBuilder: (context, i) {
                final u = employees[i];
                final company = bank.companyById(u.companyId);
                final contractDays =
                    u.contractEnd.difference(DateTime.now()).inDays;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    shape: const RoundedRectangleBorder(side: BorderSide.none),
                    leading: CircleAvatar(
                      child: Text(u.fullName[0].toUpperCase()),
                    ),
                    title: Text(u.fullName,
                        style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${u.title} • ${company?.name ?? "Şirketsiz"}'),
                    trailing: Text(money(u.balance, bank.currency),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow('E-posta', u.email),
                            _infoRow('Maaş', money(u.salary, bank.currency)),
                            _infoRow(
                                'Aylık Prim', money(u.bonus, bank.currency)),
                            _infoRow('Maaş Günü',
                                'Her ayın ${u.salaryDate.day}. günü'),
                            _infoRow(
                                'Sözleşme Bitiş',
                                DateFormat('dd.MM.yyyy').format(u.contractEnd)),
                            _infoRow(
                                'Fesih Ücreti',
                                money(u.terminationFee, bank.currency)),
                            if (contractDays < 0)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text('⚠️ Sözleşme süresi dolmuş',
                                    style: TextStyle(color: Colors.orange)),
                              ),
                            const Divider(height: 24),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilledButton.tonalIcon(
                                  icon: const Icon(Icons.payments, size: 18),
                                  label: const Text('Maaş Öde'),
                                  onPressed: () => _paySalary(context, u),
                                ),
                                FilledButton.tonalIcon(
                                  icon: const Icon(Icons.card_giftcard,
                                      size: 18),
                                  label: const Text('Prim Ver'),
                                  onPressed: () => _bonus(context, u),
                                ),
                                FilledButton.tonalIcon(
                                  icon: const Icon(Icons.warning_amber,
                                      size: 18, color: Colors.red),
                                  label: const Text('Ceza Uygula'),
                                  onPressed: () => _penalty(context, u),
                                ),
                                FilledButton.tonalIcon(
                                  icon: const Icon(Icons.trending_up,
                                      size: 18, color: Colors.green),
                                  label: const Text('Terfi Ettir'),
                                  onPressed: () => _promote(context, u),
                                ),
                                FilledButton.tonalIcon(
                                  icon: const Icon(Icons.casino, size: 18),
                                  label: const Text('Kesinti Yap'),
                                  onPressed: () {
                                    final d = bank.applyRandomDeduction(u.id);
                                    showSnackBar(context,
                                        '${money(d, bank.currency)} kesinti yapıldı.');
                                  },
                                ),
                                FilledButton.tonalIcon(
                                  icon: const Icon(Icons.swap_horiz, size: 18),
                                  label: const Text('Şirket Değiştir'),
                                  onPressed: () => _transfer(context, u),
                                ),
                                FilledButton.tonalIcon(
                                  icon: const Icon(Icons.description,
                                      size: 18),
                                  label: const Text('Sözleşme Yenile'),
                                  onPressed: () => _renewContract(context, u),
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.receipt_long,
                                      size: 18),
                                  label: const Text('Geçmiş'),
                                  onPressed: () =>
                                      _showHistory(context, u),
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 18, color: Colors.red),
                                  label: const Text('Sil',
                                      style: TextStyle(color: Colors.red)),
                                  onPressed: () => showConfirmDialog(
                                    context,
                                    title: 'Kullanıcıyı Sil',
                                    message:
                                        '${u.fullName} silinecek. Emin misiniz?',
                                    onConfirm: () {
                                      bank.deleteUser(u.id);
                                      showSnackBar(
                                          context, 'Kullanıcı silindi.');
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.person_add),
        label: const Text('Yeni Kullanıcı'),
        onPressed: () => _addUser(context),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _paySalary(BuildContext context, AppUser u) {
    final bank = context.read<BankProvider>();
    try {
      bank.paySalary(u.id);
      showSnackBar(context,
          '${money(u.salary, bank.currency)} maaş ödendi.');
    } catch (e) {
      showSnackBar(context, e.toString(), error: true);
    }
  }

  void _bonus(BuildContext context, AppUser u) {
    final ctrl = TextEditingController();
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${u.fullName} - Prim'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Prim tutarı', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
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
                  .giveBonus(u.id, v, noteCtrl.text);
              Navigator.pop(ctx);
              showSnackBar(context, 'Prim verildi.');
            },
            child: const Text('Ver'),
          ),
        ],
      ),
    );
  }

  void _penalty(BuildContext context, AppUser u) {
    final ctrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    bool isPercent = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          title: Text('${u.fullName} - Ceza'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isPercent ? 'Maaş yüzdesi (%)' : 'Ceza tutarı',
                  border: const OutlineInputBorder(),
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Maaş üzerinden yüzde'),
                value: isPercent,
                onChanged: (v) => setS(() => isPercent = v),
              ),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                    labelText: 'Ceza nedeni',
                    border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İptal')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                final v = double.tryParse(ctrl.text);
                if (v == null) return;
                try {
                  context.read<BankProvider>().applyPenalty(
                      u.id, v, reasonCtrl.text,
                      percentage: isPercent);
                  Navigator.pop(ctx);
                  showSnackBar(context, 'Ceza uygulandı.');
                } catch (e) {
                  showSnackBar(context, e.toString(), error: true);
                }
              },
              child: const Text('Uygula'),
            ),
          ],
        );
      }),
    );
  }

  void _promote(BuildContext context, AppUser u) {
    final titleCtrl = TextEditingController(text: u.title);
    final salaryCtrl =
        TextEditingController(text: (u.salary * 1.2).toStringAsFixed(0));
    final bonusCtrl = TextEditingController(text: '0');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${u.fullName} - Terfi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                  labelText: 'Yeni Unvan', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: salaryCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Yeni Maaş', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bonusCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Terfi Primi (opsiyonel)',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal')),
          FilledButton(
            onPressed: () {
              final s = double.tryParse(salaryCtrl.text);
              final b = double.tryParse(bonusCtrl.text) ?? 0;
              if (s == null) return;
              context
                  .read<BankProvider>()
                  .promote(u.id, titleCtrl.text, s, b);
              Navigator.pop(ctx);
              showSnackBar(context, 'Terfi uygulandı.');
            },
            child: const Text('Terfi Ettir'),
          ),
        ],
      ),
    );
  }

  void _transfer(BuildContext context, AppUser u) {
    final bank = context.read<BankProvider>();
    String? targetId;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          title: Text('${u.fullName} - Şirket Değiştir'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (u.contractEnd.isAfter(DateTime.now()))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    '⚠️ Sözleşme devam ediyor. Fesih ücreti: ${money(u.terminationFee, bank.currency)}',
                    style: const TextStyle(color: Colors.orange),
                  ),
                ),
              DropdownButtonFormField<String>(
                value: targetId,
                decoration: const InputDecoration(
                    labelText: 'Yeni Şirket',
                    border: OutlineInputBorder()),
                items: bank.companies
                    .where((c) => c.id != u.companyId)
                    .map((c) => DropdownMenuItem(
                        value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setS(() => targetId = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İptal')),
            FilledButton(
              onPressed: () {
                if (targetId == null) return;
                try {
                  bank.transferEmployee(u.id, targetId!);
                  Navigator.pop(ctx);
                  showSnackBar(context, 'Çalışan transfer edildi.');
                } catch (e) {
                  showSnackBar(context, e.toString(), error: true);
                }
              },
              child: const Text('Transfer Et'),
            ),
          ],
        );
      }),
    );
  }

  void _renewContract(BuildContext context, AppUser u) {
    final monthsCtrl = TextEditingController(text: '12');
    final feeCtrl =
        TextEditingController(text: u.terminationFee.toStringAsFixed(0));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sözleşme Yenile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: monthsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Süre (ay)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feeCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Fesih Ücreti',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal')),
          FilledButton(
            onPressed: () {
              final m = int.tryParse(monthsCtrl.text) ?? 12;
              final f = double.tryParse(feeCtrl.text) ?? 0;
              context.read<BankProvider>().renewContract(u.id, m, f);
              Navigator.pop(ctx);
              showSnackBar(context, 'Sözleşme yenilendi.');
            },
            child: const Text('Yenile'),
          ),
        ],
      ),
    );
  }

  void _showHistory(BuildContext context, AppUser u) {
    final bank = context.read<BankProvider>();
    final txns = bank.txnsOfUser(u.id);
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
              child: Text('${u.fullName} - İşlemler',
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
                        final isIncoming = t.toId == u.id;
                        return ListTile(
                          leading: Icon(TxnIcon.of(t.type),
                              color: TxnIcon.colorOf(t.type)),
                          title: Text(t.type.label),
                          subtitle: Text(t.description),
                          trailing: Text(
                            '${isIncoming ? "+" : "-"}${money(t.amount, bank.currency)}',
                            style: TextStyle(
                              color: isIncoming ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
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

  void _addUser(BuildContext context) {
    final bank = context.read<BankProvider>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: '123456');
    final titleCtrl = TextEditingController(text: 'Çalışan');
    final salaryCtrl = TextEditingController(text: '30000');
    final feeCtrl = TextEditingController(text: '30000');
    String? companyId =
        bank.companies.isNotEmpty ? bank.companies.first.id : null;
    int salaryDay = bank.settings.salaryDay;
    int contractMonths = 12;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        return AlertDialog(
          title: const Text('Yeni Kullanıcı'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Ad Soyad',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                      labelText: 'E-posta',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Şifre', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: companyId,
                  decoration: const InputDecoration(
                      labelText: 'Şirket',
                      border: OutlineInputBorder()),
                  items: bank.companies
                      .map((c) => DropdownMenuItem(
                          value: c.id, child: Text(c.name)))
                      .toList(),
                  onChanged: (v) => setS(() => companyId = v),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Unvan', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: salaryCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Maaş', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: salaryDay.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Maaş Günü',
                            border: OutlineInputBorder()),
                        onChanged: (v) =>
                            salaryDay = int.tryParse(v) ?? 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: contractMonths.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Sözleşme (ay)',
                            border: OutlineInputBorder()),
                        onChanged: (v) =>
                            contractMonths = int.tryParse(v) ?? 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: feeCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Fesih Ücreti',
                      border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İptal')),
            FilledButton(
              onPressed: () {
                final now = DateTime.now();
                bank.addUser(
                  fullName: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  password: passCtrl.text,
                  role: UserRole.employee,
                  companyId: companyId,
                  title: titleCtrl.text,
                  salary: double.tryParse(salaryCtrl.text) ?? 0,
                  salaryDate:
                      DateTime(now.year, now.month, salaryDay),
                  contractEnd:
                      now.add(Duration(days: contractMonths * 30)),
                  terminationFee: double.tryParse(feeCtrl.text) ?? 0,
                );
                Navigator.pop(ctx);
                showSnackBar(context, 'Kullanıcı oluşturuldu.');
              },
              child: const Text('Oluştur'),
            ),
          ],
        );
      }),
    );
  }
}
