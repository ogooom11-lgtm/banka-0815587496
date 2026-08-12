import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/bank_provider.dart';
import '../../models/bank_settings.dart';
import '../../widgets/common.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late TextEditingController _bankName;
  late TextEditingController _currency;
  late TextEditingController _dedMin;
  late TextEditingController _dedMax;
  late TextEditingController _salaryDay;

  @override
  void initState() {
    super.initState();
    final s = context.read<BankProvider>().settings;
    _bankName = TextEditingController(text: s.bankName);
    _currency = TextEditingController(text: s.currency);
    _dedMin =
        TextEditingController(text: s.randomDeductionMin.toStringAsFixed(0));
    _dedMax =
        TextEditingController(text: s.randomDeductionMax.toStringAsFixed(0));
    _salaryDay = TextEditingController(text: s.salaryDay.toString());
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Banka Ayarları',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                    controller: _bankName,
                    decoration: const InputDecoration(
                      labelText: 'Banka Adı',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _currency,
                    decoration: const InputDecoration(
                      labelText: 'Para Birimi Sembolü',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _salaryDay,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Varsayılan Maaş Günü (ayın günü)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Rastgele Kredi Kesintisi Ayarları',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _dedMin,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Minimum',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _dedMax,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Maksimum',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Ayarları Kaydet'),
            onPressed: () {
              final s = BankSettings(
                bankName: _bankName.text,
                currency: _currency.text,
                salaryDay: int.tryParse(_salaryDay.text) ?? 1,
                randomDeductionMin:
                    double.tryParse(_dedMin.text) ?? 50,
                randomDeductionMax:
                    double.tryParse(_dedMax.text) ?? 500,
              );
              context.read<BankProvider>().updateSettings(s);
              showSnackBar(context, 'Ayarlar kaydedildi.');
            },
          ),
          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 16),
          Text('Tehlikeli Bölge',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(color: Colors.red)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.restore, color: Colors.red),
            label: const Text('Tüm Verileri Sıfırla',
                style: TextStyle(color: Colors.red)),
            onPressed: () => showConfirmDialog(
              context,
              title: 'Verileri Sıfırla',
              message:
                  'Tüm şirketler, kullanıcılar ve işlemler silinecek. Bu işlem geri alınamaz!',
              confirmText: 'Sıfırla',
              onConfirm: () {
                context.read<BankProvider>().resetAll();
                showSnackBar(context, 'Sistem sıfırlandı.');
              },
            ),
          ),
        ],
      ),
    );
  }
}
