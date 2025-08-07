import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

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
        _solves = jsonList.map<Map<String, String>>((e) => {
          'time': e['time'] as String,
          'date': e['date'] as String,
        }).toList();
      }
    } catch (_) {}
    _loaded = true;
    notifyListeners();
  }

  Future<void> save() async {
    final file = await _localFile;
    await file.writeAsString(jsonEncode(_solves));
  }

  void addSolve(Map<String, String> solve) {
    _solves.add(solve);
    save();
    notifyListeners();
  }

  void deleteSolve(Map<String, String> solve) {
    _solves.removeWhere((e) => e['time'] == solve['time'] && e['date'] == solve['date']);
    save();
    notifyListeners();
  }

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