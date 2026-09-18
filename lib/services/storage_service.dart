import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String countKey = 'count';
  static const String targetKey = 'target';
  static const String zikrKey = 'zikr';
  static const String totalKey = 'total';
  static const String vibrationKey = 'vibration';
  static const String darkModeKey = 'darkMode';
  static const String historyKey = 'history';

  static const String zikrCountsKey = 'zikrCounts';
  static const String todayDateKey = 'todayDate';
  static const String todayCountsKey = 'todayCounts';

  static Future<void> saveCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(countKey, count);
  }

  static Future<int> getCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(countKey) ?? 0;
  }

  static Future<void> saveTarget(int target) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(targetKey, target);
  }

  static Future<int> getTarget() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(targetKey) ?? 33;
  }

  static Future<void> saveZikr(String zikrId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(zikrKey, zikrId);
  }

  static Future<String?> getZikr() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(zikrKey);
  }

  static Future<void> saveTotal(int total) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(totalKey, total);
  }

  static Future<int> getTotal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(totalKey) ?? 0;
  }

  static Future<void> saveVibration(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(vibrationKey, enabled);
  }

  static Future<bool> getVibration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(vibrationKey) ?? false;
  }

  static Future<void> saveDarkMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(darkModeKey, enabled);
  }

  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(darkModeKey) ?? false;
  }

  static Future<Map<String, int>> _getMap(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(key);

    if (saved == null || saved.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(saved);

      if (decoded is Map) {
        final result = <String, int>{};

        decoded.forEach((key, value) {
          if (value is int) {
            result[key.toString()] = value;
          } else if (value is num) {
            result[key.toString()] = value.toInt();
          }
        });

        return result;
      }
    } catch (_) {}

    return {};
  }

  static Future<void> _saveMap(
    String key,
    Map<String, int> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      key,
      jsonEncode(data),
    );
  }

  static Future<int> getZikrCount(String zikrId) async {
    final counts = await _getMap(zikrCountsKey);
    return counts[zikrId] ?? 0;
  }

  static Future<void> saveZikrCount(
    String zikrId,
    int count,
  ) async {
    final counts = await _getMap(zikrCountsKey);

    counts[zikrId] = count;

    await _saveMap(
      zikrCountsKey,
      counts,
    );
  }

  static Future<void> resetZikrCount(String zikrId) async {
    final counts = await _getMap(zikrCountsKey);

    counts[zikrId] = 0;

    await _saveMap(
      zikrCountsKey,
      counts,
    );
  }

  static String _getTodayDate() {
    final now = DateTime.now();

    return '${now.year}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

  static Future<void> _checkToday() async {
    final prefs = await SharedPreferences.getInstance();

    final today = _getTodayDate();
    final savedDate = prefs.getString(todayDateKey);

    if (savedDate != today) {
      await prefs.setString(
        todayDateKey,
        today,
      );

      await prefs.setString(
        todayCountsKey,
        jsonEncode({}),
      );
    }
  }

  static Future<Map<String, int>> getTodayCounts() async {
    await _checkToday();

    return await _getMap(
      todayCountsKey,
    );
  }

  static Future<int> getTodayZikrCount(String zikrId) async {
    final counts = await getTodayCounts();

    return counts[zikrId] ?? 0;
  }

  static Future<void> saveTodayZikrCount(
    String zikrId,
    int count,
  ) async {
    final counts = await getTodayCounts();

    counts[zikrId] = count;

    await _saveMap(
      todayCountsKey,
      counts,
    );
  }

  static Future<int> addTodayZikr(String zikrId) async {
    final counts = await getTodayCounts();

    final newCount = (counts[zikrId] ?? 0) + 1;

    counts[zikrId] = newCount;

    await _saveMap(
      todayCountsKey,
      counts,
    );

    return newCount;
  }

  static Future<int> getTodayTotal() async {
    final counts = await getTodayCounts();

    int total = 0;

    for (final value in counts.values) {
      total += value;
    }

    return total;
  }

  static Future<void> saveHistory(
    String date,
    String zikrName,
    int count,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    final history =
        prefs.getStringList(historyKey) ?? [];

    final item = jsonEncode({
      'date': date,
      'zikrName': zikrName,
      'count': count,
    });

    history.add(item);

    await prefs.setStringList(
      historyKey,
      history,
    );
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();

    final saved =
        prefs.getStringList(historyKey) ?? [];

    final result =
        <Map<String, dynamic>>[];

    for (final item in saved) {
      try {
        final decoded = jsonDecode(item);

        if (decoded is Map) {
          result.add(
            Map<String, dynamic>.from(decoded),
          );
        }
      } catch (_) {}
    }

    return result;
  }

  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(historyKey);
  }
  static Future<void> resetAllCountingData() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(countKey);
    await prefs.remove(totalKey);
    await prefs.remove(zikrCountsKey);
    await prefs.remove(todayDateKey);
    await prefs.remove(todayCountsKey);
    await prefs.remove(historyKey);
  }
}
