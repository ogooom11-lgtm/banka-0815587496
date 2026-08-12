import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/app_user.dart';
import '../models/company.dart';
import '../models/transaction.dart';
import '../models/bank_settings.dart';
import '../services/storage_service.dart';

/// Basit şifre hashleme (demo amaçlı - gerçek projede bcrypt kullanın)
String _hash(String s) => s.codeUnits.fold<int>(
      5381,
      (prev, c) => ((prev << 5) + prev) + c,
    ).toRadixString(16);

class BankProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final _rnd = Random();

  List<AppUser> _users = [];
  List<Company> _companies = [];
  List<Txn> _transactions = [];
  BankSettings settings = BankSettings();

  AppUser? currentUser;
  bool initialized = false;

  List<AppUser> get users => List.unmodifiable(_users);
  List<Company> get companies => List.unmodifiable(_companies);
  List<Txn> get transactions =>
      _transactions.reversed.toList(growable: false);

  String get currency => settings.currency;
  String get bankName => settings.bankName;

  // ---------- Başlatma ----------
  Future<void> init() async {
    final data = await _storage.loadAll();
    _users = (data['users'] as List)
        .map((e) => AppUser.fromJson(e))
        .toList();
    _companies = (data['companies'] as List)
        .map((e) => Company.fromJson(e))
        .toList();
    _transactions = (data['transactions'] as List)
        .map((e) => Txn.fromJson(e))
        .toList();
    final s = data['settings'] as Map<String, dynamic>;
    if (s.isNotEmpty) settings = BankSettings.fromJson(s);

    if (_users.isEmpty) _seed();
    initialized = true;
    notifyListeners();
  }

  void _seed() {
    // Varsayılan süper admin
    final admin = AppUser(
      id: 'admin-001',
      fullName: 'Banka Sahibi',
      email: 'admin@bank.com',
      passwordHash: _hash('admin123'),
      role: UserRole.superAdmin,
      salaryDate: DateTime.now(),
      contractStart: DateTime.now(),
      contractEnd: DateTime.now().add(const Duration(days: 36500)),
    );
    _users.add(admin);

    // Örnek şirket
    final c = Company(
      id: 'comp-001',
      name: 'TechCorp A.Ş.',
      balance: 1000000,
      createdAt: DateTime.now(),
    );
    _companies.add(c);

    // Örnek çalışan
    final emp = AppUser(
      id: 'emp-001',
      fullName: 'Ahmet Yılmaz',
      email: 'ahmet@techcorp.com',
      passwordHash: _hash('123456'),
      role: UserRole.employee,
      companyId: c.id,
      title: 'Yazılım Geliştirici',
      salary: 45000,
      salaryDate: DateTime(DateTime.now().year, DateTime.now().month, 1),
      contractStart: DateTime.now(),
      contractEnd: DateTime.now().add(const Duration(days: 365)),
      terminationFee: 50000,
    );
    _users.add(emp);

    addTxn(TxnType.system, c.balance, 'BANK', c.id, 'Şirket kuruldu ve kredi yüklendi');
    _persist();
  }

  Future<void> _persist() async {
    await _storage.saveAll(
      users: _users.map((e) => e.toJson()).toList(),
      companies: _companies.map((e) => e.toJson()).toList(),
      transactions: _transactions.map((e) => e.toJson()).toList(),
      settings: settings.toJson(),
    );
  }

  // ---------- İşlem kaydı ----------
  void addTxn(TxnType type, double amount, String from, String to, String desc) {
    _transactions.add(Txn(
      id: 'txn-${DateTime.now().microsecondsSinceEpoch}-${_rnd.nextInt(9999)}',
      type: type,
      amount: amount,
      fromId: from,
      toId: to,
      description: desc,
      date: DateTime.now(),
    ));
  }

  // ---------- Auth ----------
  bool login(String email, String password) {
    final hash = _hash(password);
    for (final u in _users) {
      if (u.email.toLowerCase() == email.toLowerCase() &&
          u.passwordHash == hash &&
          u.isActive) {
        currentUser = u;
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  // ---------- Şirket yönetimi ----------
  void addCompany(String name, double balance) {
    final c = Company(
      id: 'comp-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      balance: balance,
      createdAt: DateTime.now(),
    );
    _companies.add(c);
    addTxn(TxnType.credit, balance, 'BANK', c.id, 'Şirket oluşturuldu - başlangıç kredisi');
    _persist();
    notifyListeners();
  }

  void updateCompanyBalance(String companyId, double newBalance, String reason) {
    final c = _companies.firstWhere((x) => x.id == companyId);
    final diff = newBalance - c.balance;
    c.balance = newBalance;
    if (diff > 0) {
      addTxn(TxnType.credit, diff, 'BANK', c.id, reason);
    } else if (diff < 0) {
      addTxn(TxnType.transfer, diff.abs(), c.id, 'BANK', reason);
    }
    _persist();
    notifyListeners();
  }

  void deleteCompany(String id) {
    _companies.removeWhere((c) => c.id == id);
    // Çalışanları serbest bırak (inaktif)
    for (final u in _users.where((u) => u.companyId == id)) {
      u.companyId = null;
      u.isActive = false;
    }
    _persist();
    notifyListeners();
  }

  // ---------- Kullanıcı yönetimi ----------
  void addUser({
    required String fullName,
    required String email,
    required String password,
    required UserRole role,
    String? companyId,
    String title = 'Çalışan',
    double salary = 0,
    DateTime? salaryDate,
    DateTime? contractEnd,
    double terminationFee = 0,
  }) {
    final now = DateTime.now();
    final u = AppUser(
      id: 'usr-${DateTime.now().microsecondsSinceEpoch}',
      fullName: fullName,
      email: email,
      passwordHash: _hash(password),
      role: role,
      companyId: companyId,
      title: title,
      salary: salary,
      salaryDate: salaryDate ?? DateTime(now.year, now.month, settings.salaryDay),
      contractStart: now,
      contractEnd: contractEnd ?? now.add(const Duration(days: 365)),
      terminationFee: terminationFee,
    );
    _users.add(u);
    addTxn(TxnType.system, 0, 'BANK', u.id, 'Kullanıcı oluşturuldu: $fullName');
    _persist();
    notifyListeners();
  }

  void updateUser(AppUser updated) {
    final idx = _users.indexWhere((u) => u.id == updated.id);
    if (idx >= 0) {
      _users[idx] = updated;
      _persist();
      if (currentUser?.id == updated.id) currentUser = updated;
      notifyListeners();
    }
  }

  void deleteUser(String id) {
    _users.removeWhere((u) => u.id == id);
    _persist();
    notifyListeners();
  }

  // ---------- Maaş ödeme ----------
  void paySalary(String userId) {
    final u = _users.firstWhere((x) => x.id == userId);
    if (u.companyId == null) return;
    final c = _companies.firstWhere((x) => x.id == u.companyId);
    if (c.balance < u.salary) {
      throw Exception('Şirket bakiyesi yetersiz! Maaş ödenemedi.');
    }
    c.balance -= u.salary;
    u.balance += u.salary;
    addTxn(TxnType.salary, u.salary, c.id, u.id,
        '${DateFormat('MMMM yyyy', 'tr_TR').format(DateTime.now())} maaşı');
    _persist();
    notifyListeners();
  }

  /// Tüm vadesi gelen maaşları öde
  int processDueSalaries() {
    final today = DateTime.now();
    int count = 0;
    for (final u in _users.where(
        (u) => u.role == UserRole.employee && u.companyId != null && u.isActive)) {
      // Maaş günü bugünden önce veya bugün ise öde
      if (!u.salaryDate.isAfter(today)) {
        try {
          paySalary(u.id);
          // Bir sonraki aya geç
          var next = DateTime(today.year, today.month, settings.salaryDay);
          if (!next.isAfter(today)) {
            next = DateTime(today.year, today.month + 1, settings.salaryDay);
          }
          u.salaryDate = next;
          count++;
        } catch (_) {}
      }
    }
    if (count > 0) _persist();
    return count;
  }

  // ---------- Prim ----------
  void giveBonus(String userId, double amount, [String? note]) {
    final u = _users.firstWhere((x) => x.id == userId);
    u.balance += amount;
    if (u.companyId != null) {
      final c = _companies.firstWhere((x) => x.id == u.companyId);
      if (c.balance >= amount) c.balance -= amount;
    }
    addTxn(TxnType.bonus, amount, u.companyId ?? 'BANK', u.id,
        note ?? 'Performans primi');
    _persist();
    notifyListeners();
  }

  void setMonthlyBonus(String userId, double amount) {
    final u = _users.firstWhere((x) => x.id == userId);
    u.bonus = amount;
    _persist();
    notifyListeners();
  }

  // ---------- Ceza ----------
  void applyPenalty(String userId, double amount, String reason,
      {bool percentage = false}) {
    final u = _users.firstWhere((x) => x.id == userId);
    double penalty = amount;
    if (percentage) {
      penalty = u.salary * amount / 100;
    }
    if (u.balance >= penalty) {
      u.balance -= penalty;
      addTxn(TxnType.penalty, penalty, u.id, u.companyId ?? 'BANK',
          'Ceza: $reason${percentage ? ' (%$amount maaş kesintisi)' : ''}');
      if (u.companyId != null) {
        final c = _companies.firstWhere((x) => x.id == u.companyId);
        c.balance += penalty;
      }
    } else {
      throw Exception('Kullanıcı bakiyesi cezayı karşılamıyor.');
    }
    _persist();
    notifyListeners();
  }

  // ---------- Terfi ----------
  void promote(String userId, String newTitle, double newSalary,
      [double bonus = 0]) {
    final u = _users.firstWhere((x) => x.id == userId);
    final oldTitle = u.title;
    final oldSalary = u.salary;
    u.title = newTitle;
    u.salary = newSalary;
    if (bonus > 0) {
      u.balance += bonus;
      if (u.companyId != null) {
        final c = _companies.firstWhere((x) => x.id == u.companyId);
        if (c.balance >= bonus) c.balance -= bonus;
      }
    }
    addTxn(TxnType.promotion, newSalary - oldSalary, u.companyId ?? 'BANK', u.id,
        'Terfi: $oldTitle → $newTitle (Maaş: ${oldSalary.toStringAsFixed(0)} → ${newSalary.toStringAsFixed(0)})${bonus > 0 ? ' + Terfi primi' : ''}');
    _persist();
    notifyListeners();
  }

  // ---------- Rastgele kredi kesintisi ----------
  double applyRandomDeduction(String userId) {
    final u = _users.firstWhere((x) => x.id == userId);
    final amount = settings.randomDeductionMin +
        _rnd.nextDouble() *
            (settings.randomDeductionMax - settings.randomDeductionMin);
    final deduction = amount.clamp(0, u.balance);
    if (deduction > 0) {
      u.balance -= deduction;
      addTxn(TxnType.randomDeduction, deduction, u.id, 'BANK',
          'Aylık rastgele kredi kesintisi');
    }
    _persist();
    notifyListeners();
    return deduction;
  }

  int applyRandomDeductionsToAll() {
    int count = 0;
    for (final u in _users.where((u) => u.role == UserRole.employee)) {
      applyRandomDeduction(u.id);
      count++;
    }
    return count;
  }

  // ---------- Sözleşme / Şirket değiştirme ----------
  void transferEmployee(String userId, String newCompanyId) {
    final u = _users.firstWhere((x) => x.id == userId);
    final now = DateTime.now();
    if (u.contractEnd.isAfter(now)) {
      // Sözleşme devam ediyor - fesih ücreti
      final fee = u.terminationFee;
      if (u.balance < fee) {
        throw Exception(
            'Sözleşme fesih ücreti (${fee.toStringAsFixed(2)} $currency) için bakiye yetersiz.');
      }
      u.balance -= fee;
      addTxn(TxnType.terminationFee, fee, u.id, u.companyId ?? 'BANK',
          'Sözleşme erken fesih ücreti');
    }
    final oldCompany = u.companyId;
    u.companyId = newCompanyId;
    u.contractStart = now;
    u.contractEnd = now.add(const Duration(days: 365));
    addTxn(TxnType.transfer, 0, oldCompany ?? 'BANK', newCompanyId,
        '${u.fullName} şirket değiştirdi');
    _persist();
    notifyListeners();
  }

  void renewContract(String userId, int months, double newTerminationFee) {
    final u = _users.firstWhere((x) => x.id == userId);
    u.contractEnd = DateTime.now().add(Duration(days: months * 30));
    u.terminationFee = newTerminationFee;
    addTxn(TxnType.system, 0, 'BANK', u.id,
        'Sözleşme yenilendi - ${DateFormat('dd.MM.yyyy').format(u.contractEnd)}');
    _persist();
    notifyListeners();
  }

  // ---------- Transfer (kullanıcıdan kullanıcıya) ----------
  void userTransfer(String fromUserId, String toUserId, double amount,
      String note) {
    final from = _users.firstWhere((x) => x.id == fromUserId);
    final to = _users.firstWhere((x) => x.id == toUserId);
    if (from.balance < amount) {
      throw Exception('Yetersiz bakiye.');
    }
    from.balance -= amount;
    to.balance += amount;
    addTxn(TxnType.transfer, amount, fromUserId, toUserId, note);
    _persist();
    notifyListeners();
  }

  // ---------- Ayarlar ----------
  void updateSettings(BankSettings s) {
    settings = s;
    addTxn(TxnType.system, 0, 'BANK', 'BANK', 'Banka ayarları güncellendi');
    _persist();
    notifyListeners();
  }

  // ---------- Sorgular ----------
  List<AppUser> usersOfCompany(String companyId) =>
      _users.where((u) => u.companyId == companyId).toList();

  List<Txn> txnsOfUser(String userId) => _transactions
      .where((t) => t.fromId == userId || t.toId == userId)
      .toList()
      .reversed
      .toList();

  List<Txn> txnsOfCompany(String companyId) => _transactions
      .where((t) => t.fromId == companyId || t.toId == companyId)
      .toList()
      .reversed
      .toList();

  Company? companyById(String? id) {
    if (id == null) return null;
    final matches = _companies.where((c) => c.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  AppUser? userById(String id) {
    final matches = _users.where((u) => u.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  double get totalCompanyBalance =>
      _companies.fold(0, (sum, c) => sum + c.balance);
  double get totalUserBalance =>
      _users.fold(0, (sum, u) => sum + u.balance);
  double get totalMonthlySalaries => _users
      .where((u) => u.role == UserRole.employee)
      .fold(0, (sum, u) => sum + u.salary);

  void resetAll() {
    _users.clear();
    _companies.clear();
    _transactions.clear();
    settings = BankSettings();
    currentUser = null;
    _storage.clearAll();
    _seed();
    notifyListeners();
  }
}
