import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class HomePage extends StatefulWidget{
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _displayTime = '00:00.000';
  List<Map<String, String>> solves = []; // Now stores time and date

  int timerState = 0;

  @override
  void initState() {
    super.initState();
    _loadSolves();
  }

  Future<File> get _localFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/solves.json');
  }

  Future<void> _saveSolves() async {
    final file = await _localFile;
    await file.writeAsString(jsonEncode(solves));
  }

  Future<void> _loadSolves() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(contents);
        setState(() {
          solves = jsonList.cast<Map<String, dynamic>>().map((e) => {
            'time': e['time'] as String,
            'date': e['date'] as String,
          }).toList();
        });
      }
    } catch (_) {}
  }

  void _startStop() {
    setState(() {
      if (_stopwatch.isRunning) {
        _stopwatch.stop();
        _timer?.cancel();
      } else {
        _stopwatch.start();
        _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
          if (_stopwatch.isRunning) {
            setState(() {
              _displayTime = _formatTime(_stopwatch.elapsedMilliseconds);
            });
          }
        });
      }
    });
  }

  void _reset() {
    setState(() {
      _stopwatch.stop();
      _stopwatch.reset();
      _timer?.cancel();
      _displayTime = '00:00.000';
    });
  }

  String _formatTime(int milliseconds) {
    int hundreds = (milliseconds / 10).truncate();
    int seconds = (hundreds / 100).truncate();
    int minutes = (seconds / 60).truncate();

    String hundredsStr = (hundreds % 100).toString().padLeft(2, '0');
    String secondsStr = (seconds % 60).toString().padLeft(2, '0');
    String minutesStr = (minutes % 60).toString().padLeft(2, '0');

    return "$minutesStr:$secondsStr.$hundredsStr";
  }

  void _addSolve(String time) {
    setState(() {
      solves.add({
        'time': time,
        'date': DateTime.now().toIso8601String(),
      });
    });
    _saveSolves();
  }

  void _deleteSolve(int index) {
    setState(() {
      solves.removeAt(index);
    });
    _saveSolves();
  }

  int getSolveCount() {
    return solves.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTapDown: (details) {
              if (timerState == 0) {
                setState(() {
                  timerState = 1;
                  _reset();
                });
              }
            },
            onTap: () {
              if (timerState == 1) {
                setState(() {
                  timerState = 2;
                  _startStop();
                });
              } else if (timerState == 2) {
                setState(() {
                  timerState = 0;
                  _startStop();
                  _addSolve(_displayTime);
                });
              }
            },
            child: Expanded(
              child: Center(
                child: Container(
                  height: 300,
                  width: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    color:  getOnColorForState(),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _displayTime,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'OpenRunde',
                          color:   getColorForState(),
                        ),
                      ),
                      _buildStateText(),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 120,
            child: solves.isEmpty
                ? Center(child: Text('No times yet', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)))
                : solveList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStateText() {
    switch (timerState) {
      case 0:
        return Text('Ready?', style: TextStyle(fontSize: 24, color:  getColorForState()));
      case 1:
        return Text('Set', style: TextStyle(fontSize: 24, color:  getColorForState()));
      case 2:
        return Text('Go!', style: TextStyle(fontSize: 24, color: getColorForState()));
      default:
        return Text('Unknown State', style: TextStyle(fontSize: 24, color:  getColorForState()));
    }
  }

  Widget solveList() {
    if (solves.isEmpty) {
      return Text("No Solves Yet");
    }

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => _buildFullSolveList(),
        );
      },
      child: _buildRecentSolves(),
    );
  }

  Widget _buildRecentSolves() {
    if (solves.isEmpty) return SizedBox();
    List<Map<String, String>> recent = solves.length <= 3
        ? solves
        : solves.sublist(solves.length - 3);
    return Column(
      children: [
        for (int i = 0; i < recent.length; i++)
          Text(
            recent[i]['time']!,
            style: TextStyle(
              fontSize: i == recent.length - 1 ? 24 : 18,
              color: Theme.of(context).colorScheme.onSurface,
              fontFamily: 'OpenRunde',
              fontWeight: FontWeight.w700,
            ),
          ),
        if (solves.length > 3)
          Text(
            "Tap to view all solves",
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface,
              fontFamily: 'OpenRunde',
            ),
          ),
      ],
    );
  }

  Widget _buildFullSolveList() {
    return Container(
      height: 400,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("All Solves", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: solves.length,
              itemBuilder: (context, index) {
                final solve = solves[index];
                return ListTile(
                  title: Text(
                    solve['time']!,
                    style: TextStyle(fontFamily: 'OpenRunde', fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    DateTime.parse(solve['date']!).toLocal().toString().split('.').first,
                    style: TextStyle(fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                    onPressed: () {
                      _deleteSolve(index);
                      Navigator.of(context).pop();
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color getColorForState() {
    switch (timerState) {
      case 0:
        return Theme.of(context).colorScheme.secondary;
      case 1:
        return Theme.of(context).colorScheme.tertiary;
      case 2:
        return Theme.of(context).colorScheme.primary;
      default:
        return Colors.grey;
    }
  }
  Color getOnColorForState() {
    switch (timerState) {
      case 0:
        return Theme.of(context).colorScheme.onSecondary;
      case 1:
        return Theme.of(context).colorScheme.onTertiary;
      case 2:
        return Theme.of(context).colorScheme.onPrimary;
      default:
        return Colors.grey;
    }
  }
}