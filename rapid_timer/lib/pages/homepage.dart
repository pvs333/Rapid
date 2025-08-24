import 'package:flutter/material.dart';
import 'dart:async';
import '../solves_store.dart'; // <-- Import your global store

class HomePage extends StatefulWidget{
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _displayTime = '00:00.00';
  int timerState = 0;

  String _scramble = "";

  @override
  void initState() {
    super.initState();
    SolvesStore().addListener(_onSolvesChanged);
    _generateScramble();
  }

  @override
  void dispose() {
    SolvesStore().removeListener(_onSolvesChanged);
    super.dispose();
  }

  void _onSolvesChanged() => setState(() {});

  // Only today's solves for display
  List<Map<String, String>> get todaySolves {
    final today = DateTime.now();
    return SolvesStore().solves.where((solve) {
      final solveDate = DateTime.parse(solve['date']!);
      return solveDate.year == today.year &&
             solveDate.month == today.month &&
             solveDate.day == today.day;
    }).toList();
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
      _displayTime = '00:00.00';
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
    SolvesStore().addSolve({
      'time': time,
      'date': DateTime.now().toIso8601String(),
      // Optionally store scramble: 'scramble': _scramble,
    });
    _generateScramble(); // Generate new scramble after each solve
  }

  void _deleteSolve(int index) {
    final solves = todaySolves;
    if (index >= 0 && index < solves.length) {
      SolvesStore().deleteSolve(solves[index]);
    }
  }

  int getSolveCount() {
    return todaySolves.length;
  }

  void _generateScramble() {
    const moves = ['R', 'L', 'U', 'D', 'F', 'B'];
    const suffixes = ['', '\'', '2'];
    final scramble = <String>[];
    String? lastMove;

    final random = DateTime.now().millisecondsSinceEpoch;
    int seed = random;
    int nextRand() => seed = 1103515245 * seed + 12345 & 0x7fffffff;

    for (int i = 0; i < 15; i++) {
      String move;
      do {
        move = moves[nextRand() % moves.length];
      } while (move == lastMove);
      lastMove = move;
      final suffix = suffixes[nextRand() % suffixes.length];
      scramble.add(move + suffix);
    }
    setState(() {
      _scramble = scramble.join(' ');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTapDown: (details) {
              if (timerState == 0) {
                setState(() {
                  timerState = 1;
                  _reset();
                });
              } else if (timerState == 2) {
                setState(() {
                  timerState = 0;
                  _startStop();
                  _addSolve(_displayTime);
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
          // --- Scramble display ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: Text(
              _scramble,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'OpenRunde',
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ),
          // --- Time list ---
          SizedBox(
            height: 120,
            child: todaySolves.isEmpty
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
    if (todaySolves.isEmpty) {
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
    if (todaySolves.isEmpty) return SizedBox();
    List<Map<String, String>> recent = todaySolves.length <= 3
        ? todaySolves
        : todaySolves.sublist(todaySolves.length - 3);
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
        if (todaySolves.length > 3)
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
    return SizedBox(
      height: 400,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text("All Solves", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          Expanded( // <-- Added Expanded here
            child: ListView.builder(
              itemCount: todaySolves.length,
              itemBuilder: (context, index) {
                final solve = todaySolves[index];
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