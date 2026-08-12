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
    final cur = bank.currency;

    return Scaffold(
      body: employees.isEmpty
          ? const Center(
              child: Text(
                'Henüz kayıtlı çalışan bulunmuyor.\n"Yeni Kullanıcı" butonuyla ekleyebilirsiniz.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: employees.length,
              itemBuilder: (context, i) {
                final u = employees[i];
                final company = bank.companyById(u.companyId);
                final contractDays =
                    u.contractEnd.difference(DateTime.now()).inDays;
                final isExpired = u.contractEnd.isBefore(DateTime.now());

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    shape: const RoundedRectangleBorder(side: BorderSide.none),
                    leading: CircleAvatar(
                      backgroundColor: u.isActive
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.grey.withAlpha(77),
                      child: Text(
                        u.fullName.isNotEmpty
                            ? u.fullName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: u.isActive
                              ? Theme.of(context).colorScheme.onPrimaryContainer
                              : Colors.grey,
                        ),
                      ),
                    ),
                    title: Row(
                      children: [
                        Text(
                          u.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (!u.isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withAlpha(51),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.red.shade400),
                            ),
                            child: const Text('PASİF',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.red)),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      '${u.title} • ${company?.name ?? "Şirketsiz"}',
                      style: const TextStyle(fontSize: 13),
                    ),
                    trailing: Text(
                      money(u.balance, cur),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow('E-posta', u.email),
                            _infoRow('Aylık Maaş', money(u.salary, cur)),
                            _infoRow('Aylık Prim', money(u.bonus, cur)),
                            _infoRow('Maaş Günü',
                                'Her ayın ${u.salaryDate.day}. günü'),
                            _infoRow('Sözleşme Bitiş',
                                DateFormat('dd.MM.yyyy').format(u.contractEnd)),
                            _infoRow('Erken Fesih Tazminatı',
                                money(u.terminationFee, cur)),
                            if (isExpired)
                              const Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text('⚠️ Sözleşme süresi dolmuş',
                                    style: TextStyle(color: Colors.orange)),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '⏳ Kalan süre: $contractDays gün',
                                  style: const TextStyle(
                                      color: Colors.blueGrey, fontSize: 12),
                                ),
                              ),
                            const Divider(height: 24),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                FilledButton.tonalIcon(
                                  icon: const Icon(Icons.payments_outlined,
                                      size: 18),
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
                                  icon: const Icon(Icons.warning_amber_rounded,
                                      size: 18, color: Colors.orange),
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
                                  icon: const Icon(Icons.casino_outlined,
                                      size: 18),
                                  label: const Text('Kesinti Yap'),
                                  onPressed: () {
                                    final d = bank.applyRandomDeduction(u.id);
                                    if (d > 0) {
                                      showSnackBar(context,
                                          '${money(d, cur)} kesinti yapıldı.');
                                    } else {
                                      showSnackBar(context,
                                          'Kullanıcı bakiyesi yetersiz olduğu için kesinti yapılamadı.',
                                          error: true);
                                    }
                                  },
                                ),
                                FilledButton.tonalIcon(
                                  icon: const Icon(Icons.swap_horiz, size: 18),
                                  label: const Text('Şirket Değiştir'),
                                  onPressed: () => _transfer(context, u),
                                ),
                                FilledButton.tonalIcon(
                                  icon: const Icon(Icons.description_outlined,
                                      size: 18),
                                  label: const Text('Sözleşme Yenile'),
                                  onPressed: () => _renewContract(context, u),
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.receipt_long_outlined,
                                      size: 18),
                                  label: const Text('İşlem Geçmişi'),
                                  onPressed: () => _showHistory(context, u),
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
                                        '"${u.fullName}" adlı kullanıcıyı sistemden silmek istediğinize emin misiniz?',
                                    confirmText: 'Kullanıcıyı Sil',
                                    confirmColor: Colors.red,
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
      padding: const EdgeInsets.symmetric(vertical: 3),
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
          '${u.fullName} adlı çalışana ${money(u.salary, bank.currency)} maaş ödendi.');
    } catch (e) {
      showSnackBar(context, e.toString().replaceAll('Exception: ', ''),
          error: true);
    }
  }

  void _bonus(BuildContext context, AppUser u) {
    final ctrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final cur = context.read<BankProvider>().currency;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${u.fullName} - Performans Primi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Prim Tutarı ($cur)',
                prefixIcon: const Icon(Icons.attach_money),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Prim Açıklaması / Not',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
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
              final raw = ctrl.text.trim().replaceAll(',', '.');
              final v = double.tryParse(raw);
              if (v == null || v <= 0) {
                showSnackBar(context, 'Geçerli ve pozitif bir prim tutarı girin.',
                    error: true);
                return;
              }
              try {
                context.read<BankProvider>().giveBonus(
                      u.id,
                      v,
                      noteCtrl.text.isEmpty
                          ? 'Performans primi'
                          : noteCtrl.text.trim(),
                    );
                Navigator.pop(ctx);
                showSnackBar(context,
                    '${u.fullName} adlı çalışana ${money(v, cur)} prim verildi.');
              } catch (e) {
                showSnackBar(
                    context, e.toString().replaceAll('Exception: ', ''),
                    error: true);
              }
            },
            child: const Text('Primi Ver'),
          ),
        ],
      ),
    );
  }

  void _penalty(BuildContext context, AppUser u) {
    final ctrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    bool isPercent = false;
    final cur = context.read<BankProvider>().currency;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('${u.fullName} - Ceza Uygula'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: isPercent
                      ? 'Maaş Yüzdesi (%)'
                      : 'Sabit Ceza Tutarı ($cur)',
                  prefixIcon: Icon(isPercent
                      ? Icons.percent
                      : Icons.attach_money),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Maaş üzerinden yüzde olarak kes'),
                value: isPercent,
                onChanged: (v) => setS(() => isPercent = v),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Ceza Nedeni / Açıklama',
                  prefixIcon: Icon(Icons.warning_amber),
                  border: OutlineInputBorder(),
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
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                final raw = ctrl.text.trim().replaceAll(',', '.');
                final v = double.tryParse(raw);
                if (v == null || v <= 0) {
                  showSnackBar(
                      context, 'Lütfen geçerli ve pozitif bir değer girin.',
                      error: true);
                  return;
                }
                if (isPercent && v > 100) {
                  showSnackBar(context, 'Yüzde 100\'den fazla olamaz.',
                      error: true);
                  return;
                }

                try {
                  context.read<BankProvider>().applyPenalty(
                        u.id,
                        v,
                        reasonCtrl.text.isEmpty
                            ? 'Disiplin cezası'
                            : reasonCtrl.text.trim(),
                        percentage: isPercent,
                      );
                  Navigator.pop(ctx);
                  showSnackBar(context, 'Ceza başarıyla uygulandı.');
                } catch (e) {
                  showSnackBar(
                      context, e.toString().replaceAll('Exception: ', ''),
                      error: true);
                }
              },
              child: const Text('Cezayı Uygula'),
            ),
          ],
        ),
      ),
    );
  }

  void _promote(BuildContext context, AppUser u) {
    final titleCtrl = TextEditingController(text: u.title);
    final salaryCtrl =
        TextEditingController(text: (u.salary * 1.2).toStringAsFixed(0));
    final bonusCtrl = TextEditingController(text: '0');
    final cur = context.read<BankProvider>().currency;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${u.fullName} - Terfi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Yeni Unvan',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: salaryCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Yeni Aylık Maaş ($cur)',
                  prefixIcon: const Icon(Icons.attach_money),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bonusCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Terfi Primi (Opsiyonel $cur)',
                  prefixIcon: const Icon(Icons.card_giftcard),
                  border: const OutlineInputBorder(),
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
              final newTitle = titleCtrl.text.trim();
              final rawSalary = salaryCtrl.text.trim().replaceAll(',', '.');
              final rawBonus = bonusCtrl.text.trim().replaceAll(',', '.');
              final s = double.tryParse(rawSalary);
              final b = double.tryParse(rawBonus) ?? 0;

              if (newTitle.isEmpty) {
                showSnackBar(context, 'Unvan boş bırakılamaz.', error: true);
                return;
              }
              if (s == null || s < 0) {
                showSnackBar(context, 'Geçerli bir yeni maaş girin.',
                    error: true);
                return;
              }
              if (b < 0) {
                showSnackBar(context, 'Terfi primi negatif olamaz.',
                    error: true);
                return;
              }

              try {
                context.read<BankProvider>().promote(u.id, newTitle, s, b);
                Navigator.pop(ctx);
                showSnackBar(context,
                    '${u.fullName} terfi ettirildi ($newTitle).');
              } catch (e) {
                showSnackBar(
                    context, e.toString().replaceAll('Exception: ', ''),
                    error: true);
              }
            },
            child: const Text('Terfi Ettir'),
          ),
        ],
      ),
    );
  }

  void _transfer(BuildContext context, AppUser u) {
    final bank = context.read<BankProvider>();
    final cur = bank.currency;
    final otherCompanies =
        bank.companies.where((c) => c.id != u.companyId).toList();

    if (otherCompanies.isEmpty) {
      showSnackBar(
          context, 'Transfer edilebilecek başka bir şirket bulunmuyor.',
          error: true);
      return;
    }

    String? targetId = otherCompanies.first.id;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text('${u.fullName} - Şirket Değiştir'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (u.contractEnd.isAfter(DateTime.now()) &&
                  u.terminationFee > 0)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withAlpha(38),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Sözleşme henüz dolmadı. Çalışandan ${money(u.terminationFee, cur)} fesih tazminatı kesilecektir.',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
              DropdownButtonFormField<String>(
                value: targetId,
                decoration: const InputDecoration(
                  labelText: 'Hedef Şirket',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
                items: otherCompanies
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
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () {
                if (targetId == null) return;
                try {
                  bank.transferEmployee(u.id, targetId!);
                  Navigator.pop(ctx);
                  showSnackBar(context, 'Çalışan başarıyla transfer edildi.');
                } catch (e) {
                  showSnackBar(
                      context, e.toString().replaceAll('Exception: ', ''),
                      error: true);
                }
              },
              child: const Text('Transfer Et'),
            ),
          ],
        ),
      ),
    );
  }

  void _renewContract(BuildContext context, AppUser u) {
    final monthsCtrl = TextEditingController(text: '12');
    final feeCtrl =
        TextEditingController(text: u.terminationFee.toStringAsFixed(0));
    final cur = context.read<BankProvider>().currency;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${u.fullName} - Sözleşme Yenile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: monthsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Uzatma Süresi (Ay)',
                prefixIcon: Icon(Icons.calendar_month),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: feeCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Erken Fesih Ücreti ($cur)',
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
              final m = int.tryParse(monthsCtrl.text);
              final rawFee = feeCtrl.text.trim().replaceAll(',', '.');
              final f = double.tryParse(rawFee);

              if (m == null || m <= 0) {
                showSnackBar(
                    context, 'Sözleşme süresi en az 1 ay olmalıdır.',
                    error: true);
                return;
              }
              if (f == null || f < 0) {
                showSnackBar(
                    context, 'Fesih ücreti negatif olamaz.', error: true);
                return;
              }

              try {
                context.read<BankProvider>().renewContract(u.id, m, f);
                Navigator.pop(ctx);
                showSnackBar(context, 'Sözleşme $m ay uzatıldı.');
              } catch (e) {
                showSnackBar(
                    context, e.toString().replaceAll('Exception: ', ''),
                    error: true);
              }
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
                  const Icon(Icons.person, color: Colors.indigo),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${u.fullName} - İşlem Geçmişi',
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
                        'Bu kullanıcıya ait kayıtlı bir işlem bulunmuyor.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      controller: scroll,
                      itemCount: txns.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (c, i) {
                        final t = txns[i];
                        final isIncoming = t.toId == u.id && t.fromId != u.id;
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

  void _addUser(BuildContext context) {
    final bank = context.read<BankProvider>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController(text: '123456');
    final titleCtrl = TextEditingController(text: 'Çalışan');
    final salaryCtrl = TextEditingController(text: '30000');
    final feeCtrl = TextEditingController(text: '30000');
    final salaryDayCtrl =
        TextEditingController(text: bank.settings.salaryDay.toString());
    final contractMonthsCtrl = TextEditingController(text: '12');

    String? selectedCompanyId =
        bank.companies.isNotEmpty ? bank.companies.first.id : null;
    final cur = bank.currency;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Yeni Çalışan Ekle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Ad Soyad',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String?>(
                  value: selectedCompanyId,
                  decoration: const InputDecoration(
                    labelText: 'Bağlı Olacağı Şirket',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Şirketsiz / Bağımsız'),
                    ),
                    ...bank.companies.map((c) => DropdownMenuItem<String?>(
                          value: c.id,
                          child: Text(c.name),
                        )),
                  ],
                  onChanged: (v) => setS(() => selectedCompanyId = v),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Unvan / Görev',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: salaryCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Aylık Maaş ($cur)',
                    prefixIcon: const Icon(Icons.attach_money),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: salaryDayCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Maaş Günü (1-31)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: contractMonthsCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Sözleşme (Ay)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: feeCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Fesih Tazminatı ($cur)',
                    prefixIcon: const Icon(Icons.security),
                    border: const OutlineInputBorder(),
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
                final name = nameCtrl.text.trim();
                final email = emailCtrl.text.trim();
                final pass = passCtrl.text;
                final rawSalary = salaryCtrl.text.trim().replaceAll(',', '.');
                final rawFee = feeCtrl.text.trim().replaceAll(',', '.');
                final salary = double.tryParse(rawSalary);
                final fee = double.tryParse(rawFee);
                final sDay = int.tryParse(salaryDayCtrl.text) ?? 1;
                final cMonths = int.tryParse(contractMonthsCtrl.text) ?? 12;

                if (name.isEmpty) {
                  showSnackBar(context, 'Ad Soyad boş bırakılamaz.',
                      error: true);
                  return;
                }
                if (email.isEmpty || !email.contains('@')) {
                  showSnackBar(context, 'Geçerli bir e-posta adresi girin.',
                      error: true);
                  return;
                }
                if (pass.length < 4) {
                  showSnackBar(
                      context, 'Şifre en az 4 karakter olmalıdır.',
                      error: true);
                  return;
                }
                if (salary == null || salary < 0) {
                  showSnackBar(context, 'Geçerli bir maaş girin.',
                      error: true);
                  return;
                }
                if (fee == null || fee < 0) {
                  showSnackBar(context, 'Fesih tazminatı negatif olamaz.',
                      error: true);
                  return;
                }
                if (sDay < 1 || sDay > 31) {
                  showSnackBar(context, 'Maaş günü 1 ile 31 arasında olmalıdır.',
                      error: true);
                  return;
                }
                if (cMonths < 1) {
                  showSnackBar(
                      context, 'Sözleşme süresi en az 1 ay olmalıdır.',
                      error: true);
                  return;
                }

                final now = DateTime.now();
                try {
                  bank.addUser(
                    fullName: name,
                    email: email,
                    password: pass,
                    role: UserRole.employee,
                    companyId: selectedCompanyId,
                    title: titleCtrl.text.trim(),
                    salary: salary,
                    salaryDate: DateTime(
                        now.year, now.month, sDay.clamp(1, 28)),
                    contractEnd: now.add(Duration(days: cMonths * 30)),
                    terminationFee: fee,
                  );
                  Navigator.pop(ctx);
                  showSnackBar(context, '"$name" adlı çalışan oluşturuldu.');
                } catch (e) {
                  showSnackBar(
                      context, e.toString().replaceAll('Exception: ', ''),
                      error: true);
                }
              },
              child: const Text('Oluştur'),
            ),
          ],
        ),
      ),
    );
  }
}
