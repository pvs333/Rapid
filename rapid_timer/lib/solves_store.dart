import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'services/firebase_sync_service.dart';

class SolvesStore extends ChangeNotifier {
  static final SolvesStore _instance = SolvesStore._internal();
  factory SolvesStore() => _instance;
  SolvesStore._internal();

  List<Map<String, String>> _solves = [];
  bool _loaded = false;

  List<Map<String, String>> get solves => List.unmodifiable(_solves);

  Future<File> get _localFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/solves.json');
  }

  Future<void> load() async {
    if (_loaded) return;
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(contents);
        _solves = jsonList
            .map<Map<String, String>>(
              (e) => {'time': e['time'] as String, 'date': e['date'] as String},
            )
            .toList();
      }
    } catch (_) {}
    _loaded = true;
    // Wire up remote updates -> local merge
    FirebaseSyncService.instance.onRemoteUpdate = mergeRemoteSolves;
    notifyListeners();
  }

  Future<void> save() async {
    final file = await _localFile;
    await file.writeAsString(jsonEncode(_solves));
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
