class Company {
  final String id;
  String name;
  double balance;
  final DateTime createdAt;

  Company({
    required this.id,
    required this.name,
    required this.balance,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'balance': balance,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Company.fromJson(Map<String, dynamic> json) => Company(
        id: json['id'],
        name: json['name'],
        balance: (json['balance'] as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt']),
      );
}
