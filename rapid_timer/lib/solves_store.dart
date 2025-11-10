import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/firebase_sync_service.dart';

class SolvesStore extends ChangeNotifier {
  static final SolvesStore _instance = SolvesStore._internal();
  factory SolvesStore() => _instance;
  SolvesStore._internal();

  List<Map<String, String>> _solves = [];
  bool _loaded = false;

  List<Map<String, String>> get solves => List.unmodifiable(_solves);

  static const _prefsKey = 'solves_json';

  Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final contents = prefs.getString(_prefsKey);
      if (contents != null && contents.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(contents);
        _solves = jsonList
            .map<Map<String, String>>(
              (e) => {'time': e['time'] as String, 'date': e['date'] as String},
            )
            .toList();
      }
    } catch (e) {
      debugPrint('[SolvesStore] load error: $e');
    }
    _loaded = true;
    // Wire up remote updates -> local merge
    FirebaseSyncService.instance.onRemoteUpdate = mergeRemoteSolves;
    notifyListeners();
  }

  Future<void> save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_solves));
    } catch (e) {
      debugPrint('[SolvesStore] save error: $e');
    }
  }

  void addSolve(Map<String, String> solve) {
    _solves.add(solve);
    save();
    // Push to cloud in background
    FirebaseSyncService.instance.pushAdd(solve);
    notifyListeners();
  }

  void deleteSolve(Map<String, String> solve) {
    _solves.removeWhere(
      (e) => e['time'] == solve['time'] && e['date'] == solve['date'],
    );
    save();
    // Reflect deletion in cloud
    FirebaseSyncService.instance.pushDelete(solve);
    notifyListeners();
  }

  /// Merge solves coming from the cloud with local solves (idempotent).
  void mergeRemoteSolves(List<Map<String, String>> remote) {
    final keys = <String>{for (final e in _solves) _keyOf(e)};
    bool changed = false;
    for (final r in remote) {
      final k = _keyOf(r);
      if (!keys.contains(k)) {
        _solves.add({'time': r['time'] ?? '', 'date': r['date'] ?? ''});
        keys.add(k);
        changed = true;
      }
    }
    if (changed) {
      save();
      notifyListeners();
    }
  }

  String _keyOf(Map<String, String> solve) =>
      '${solve['date']}|${solve['time']}';

  Map<DateTime, List<Map<String, String>>> get solvesByDate {
    final Map<DateTime, List<Map<String, String>>> solvesMap = {};
    for (var e in solves) {
      final date = DateTime.parse(e['date'] as String);
      final day = DateTime(date.year, date.month, date.day);
      solvesMap.putIfAbsent(day, () => []);
      solvesMap[day]!.add({
        'time': e['time'] as String,
        'date': e['date'] as String,
      });
    }
    return solvesMap;
  }
}
