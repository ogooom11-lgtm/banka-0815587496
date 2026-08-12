enum TxnType {
  salary,
  bonus,
  penalty,
  randomDeduction,
  promotion,
  transfer,
  credit,
  terminationFee,
  system,
}

extension TxnTypeLabel on TxnType {
  String get label {
    switch (this) {
      case TxnType.salary:
        return 'Maaş';
      case TxnType.bonus:
        return 'Performans Primi';
      case TxnType.penalty:
        return 'Ceza';
      case TxnType.randomDeduction:
        return 'Rastgele Kredi Kesintisi';
      case TxnType.promotion:
        return 'Terfi';
      case TxnType.transfer:
        return 'Transfer';
      case TxnType.credit:
        return 'Kredi Yükleme';
      case TxnType.terminationFee:
        return 'Sözleşme Fesih Ücreti';
      case TxnType.system:
        return 'Sistem';
    }
  }
}

class Txn {
  final String id;
  final TxnType type;
  final double amount;
  final String fromId; // company/user id or 'BANK'
  final String toId;
  final String description;
  final DateTime date;

  Txn({
    required this.id,
    required this.type,
    required this.amount,
    required this.fromId,
    required this.toId,
    required this.description,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'fromId': fromId,
        'toId': toId,
        'description': description,
        'date': date.toIso8601String(),
      };

  factory Txn.fromJson(Map<String, dynamic> json) => Txn(
        id: json['id'],
        type: TxnType.values.firstWhere((t) => t.name == json['type']),
        amount: (json['amount'] as num).toDouble(),
        fromId: json['fromId'],
        toId: json['toId'],
        description: json['description'],
        date: DateTime.parse(json['date']),
      );
}
