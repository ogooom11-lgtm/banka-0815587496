import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

final _trFmt = NumberFormat.currency(locale: 'tr_TR', symbol: '');

String money(double v, String currency) =>
    '${_trFmt.format(v)} $currency';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final String? subtitle;
  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: c.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: c, size: 24),
            ),
            const SizedBox(height: 12),
            Text(title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
            ]
          ],
        ),
      ),
    );
  }
}

class TxnIcon {
  static IconData of(TxnType t) {
    switch (t) {
      case TxnType.salary:
        return Icons.payments_outlined;
      case TxnType.bonus:
        return Icons.card_giftcard;
      case TxnType.penalty:
        return Icons.warning_amber;
      case TxnType.randomDeduction:
        return Icons.casino_outlined;
      case TxnType.promotion:
        return Icons.trending_up;
      case TxnType.transfer:
        return Icons.swap_horiz;
      case TxnType.credit:
        return Icons.account_balance_wallet;
      case TxnType.terminationFee:
        return Icons.description;
      case TxnType.system:
        return Icons.settings;
    }
  }

  static Color colorOf(TxnType t) {
    switch (t) {
      case TxnType.salary:
      case TxnType.bonus:
      case TxnType.promotion:
      case TxnType.credit:
        return Colors.green;
      case TxnType.penalty:
      case TxnType.randomDeduction:
      case TxnType.terminationFee:
        return Colors.red;
      case TxnType.transfer:
        return Colors.blue;
      case TxnType.system:
        return Colors.grey;
    }
  }
}

Future<void> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required VoidCallback onConfirm,
  String confirmText = 'Onayla',
}) async {
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            onConfirm();
          },
          child: Text(confirmText),
        ),
      ],
    ),
  );
}

void showSnackBar(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red.shade700 : null,
      behavior: SnackBarBehavior.floating,
    ),
  );
}
