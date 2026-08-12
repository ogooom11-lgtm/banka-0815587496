enum UserRole { superAdmin, companyAdmin, employee }

class AppUser {
  final String id;
  String fullName;
  final String email;
  final String passwordHash;
  UserRole role;
  String? companyId; // null for superAdmin
  String title;
  double salary;
  double bonus; // performans primi (aylık)
  double balance; // kişisel bakiye
  DateTime salaryDate; // maaş günü (her ayın bu günü)
  DateTime contractStart;
  DateTime contractEnd;
  double terminationFee; // sözleşme fesih ücreti
  bool isActive;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.passwordHash,
    required this.role,
    this.companyId,
    this.title = 'Çalışan',
    this.salary = 0,
    this.bonus = 0,
    this.balance = 0,
    required this.salaryDate,
    required this.contractStart,
    required this.contractEnd,
    this.terminationFee = 0,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'passwordHash': passwordHash,
        'role': role.name,
        'companyId': companyId,
        'title': title,
        'salary': salary,
        'bonus': bonus,
        'balance': balance,
        'salaryDate': salaryDate.toIso8601String(),
        'contractStart': contractStart.toIso8601String(),
        'contractEnd': contractEnd.toIso8601String(),
        'terminationFee': terminationFee,
        'isActive': isActive,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'],
        fullName: json['fullName'],
        email: json['email'],
        passwordHash: json['passwordHash'],
        role: UserRole.values.firstWhere((r) => r.name == json['role']),
        companyId: json['companyId'],
        title: json['title'] ?? 'Çalışan',
        salary: (json['salary'] as num).toDouble(),
        bonus: (json['bonus'] as num?)?.toDouble() ?? 0,
        balance: (json['balance'] as num).toDouble(),
        salaryDate: DateTime.parse(json['salaryDate']),
        contractStart: DateTime.parse(json['contractStart']),
        contractEnd: DateTime.parse(json['contractEnd']),
        terminationFee: (json['terminationFee'] as num?)?.toDouble() ?? 0,
        isActive: json['isActive'] ?? true,
      );
}
