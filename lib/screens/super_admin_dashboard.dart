import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/bank_provider.dart';
import '../widgets/common.dart';
import 'tabs/companies_tab.dart';
import 'tabs/users_tab.dart';
import 'tabs/transactions_tab.dart';
import 'tabs/settings_tab.dart';
import 'tabs/overview_tab.dart';

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({super.key});

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> {
  int _index = 0;

  final _tabs = const [
    OverviewTab(),
    CompaniesTab(),
    UsersTab(),
    TransactionsTab(),
    SettingsTab(),
  ];

  final _titles = const [
    'Genel Bakış',
    'Şirketler',
    'Kullanıcılar',
    'İşlem Geçmişi',
    'Ayarlar',
  ];

  final _icons = const [
    Icons.dashboard_outlined,
    Icons.business_outlined,
    Icons.people_outline,
    Icons.receipt_long_outlined,
    Icons.settings_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final bank = context.watch<BankProvider>();
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.account_balance),
            const SizedBox(width: 8),
            Text(bank.bankName),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber),
              ),
              child: const Text('SÜPER ADMIN',
                  style: TextStyle(fontSize: 10, color: Colors.amber)),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tüm vadesi gelen maaşları öde',
            icon: const Icon(Icons.payments),
            onPressed: () {
              final n = bank.processDueSalaries();
              showSnackBar(context, '$n kullanıcıya maaş ödendi.');
            },
          ),
          IconButton(
            tooltip: 'Rastgele kredi kesintilerini uygula',
            icon: const Icon(Icons.casino),
            onPressed: () {
              final n = bank.applyRandomDeductionsToAll();
              showSnackBar(context, '$n kullanıcıya kesinti uygulandı.');
            },
          ),
          const SizedBox(width: 8),
          Center(
            child: Text(bank.currentUser?.fullName ?? '',
                style: const TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => bank.logout(),
          ),
        ],
      ),
      body: isWide
          ? Row(
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  extended: true,
                  minExtendedWidth: 200,
                  destinations: [
                    for (int i = 0; i < _titles.length; i++)
                      NavigationRailDestination(
                        icon: Icon(_icons[i]),
                        label: Text(_titles[i]),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _tabs[_index]),
              ],
            )
          : Column(
              children: [
                Expanded(child: _tabs[_index]),
                NavigationBar(
                  selectedIndex: _index,
                  onDestinationSelected: (i) => setState(() => _index = i),
                  destinations: [
                    for (int i = 0; i < _titles.length; i++)
                      NavigationDestination(
                          icon: Icon(_icons[i]), label: _titles[i]),
                  ],
                ),
              ],
            ),
    );
  }
}
