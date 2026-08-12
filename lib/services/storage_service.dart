import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Basit kalıcı depolama - SharedPreferences tabanlı
class StorageService {
  static const _usersKey = 'users';
  static const _companiesKey = 'companies';
  static const _transactionsKey = 'transactions';
  static const _settingsKey = 'settings';

  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  Future<Map<String, dynamic>> loadAll() async {
    final p = await _prefs;
    return {
      'users': jsonDecode(p.getString(_usersKey) ?? '[]'),
      'companies': jsonDecode(p.getString(_companiesKey) ?? '[]'),
      'transactions': jsonDecode(p.getString(_transactionsKey) ?? '[]'),
      'settings': jsonDecode(p.getString(_settingsKey) ?? '{}'),
    };
  }

  Future<void> saveAll({
    required List<Map<String, dynamic>> users,
    required List<Map<String, dynamic>> companies,
    required List<Map<String, dynamic>> transactions,
    required Map<String, dynamic> settings,
  }) async {
    final p = await _prefs;
    await p.setString(_usersKey, jsonEncode(users));
    await p.setString(_companiesKey, jsonEncode(companies));
    await p.setString(_transactionsKey, jsonEncode(transactions));
    await p.setString(_settingsKey, jsonEncode(settings));
  }

  Future<void> clearAll() async {
    final p = await _prefs;
    await p.clear();
  }
}
