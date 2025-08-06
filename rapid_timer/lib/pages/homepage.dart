import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
  // Timer to update the UI periodically.
  Timer? _timer;
  // The formatted string to display the elapsed time.
  String _displayTime = '00:00.000';
  // List to store lap times.
  final List<String> solves = [];

  int timerState = 0;

  // Starts or stops the stopwatch.
  void _startStop() {
    setState(() {
      if (_stopwatch.isRunning) {
        // If it's running, stop it and cancel the timer.
        _stopwatch.stop();
        _timer?.cancel();
      } else {
        // If it's stopped, start it and create a timer to update the UI.
        _stopwatch.start();
        _timer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
          // Update the display time while the stopwatch is running.
          if (_stopwatch.isRunning) {
            setState(() {
              _displayTime = _formatTime(_stopwatch.elapsedMilliseconds);
            });
          }
        });
      }
    });
  }

  // Resets the stopwatch and clears laps.
  void _reset() {
    setState(() {
      _stopwatch.stop();
      _stopwatch.reset();
      _timer?.cancel();
      _displayTime = '00:00.000';
      // solves.clear(); // Remove this line to keep solves
    });
  }

   // Formats milliseconds into a readable HH:MM:SS.ms string.
  String _formatTime(int milliseconds) {
    int hundreds = (milliseconds / 10).truncate();
    int seconds = (hundreds / 100).truncate();
    int minutes = (seconds / 60).truncate();

    String hundredsStr = (hundreds % 100).toString().padLeft(2, '0');
    String secondsStr = (seconds % 60).toString().padLeft(2, '0');
    String minutesStr = (minutes % 60).toString().padLeft(2, '0');

    return "$minutesStr:$secondsStr.$hundredsStr";
  }

  List<List<String>> sets = []; // List of sets, each set is a list of solves
  int currentSetIndex = 0;

  @override
  void initState() {
    super.initState();
    sets.add(solves); // Initialize with the first set
    _loadSets();
  }

  // Save sets to JSON file
  Future<void> _saveSets() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/solves_sets.json');
    await file.writeAsString(jsonEncode(sets));
  }

  // Load sets from JSON file
  Future<void> _loadSets() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/solves_sets.json');
    if (await file.exists()) {
      final content = await file.readAsString();
      final loadedSets = jsonDecode(content);
      setState(() {
        sets = List<List<String>>.from(
          loadedSets.map((set) => List<String>.from(set)),
        );
        currentSetIndex = 0;
        solves
          ..clear()
          ..addAll(sets.isNotEmpty ? sets[0] : []);
      });
    }
  }

  // Create a new set
  void _newSet() {
    setState(() {
      solves.clear();
      sets.add([]);
      currentSetIndex = sets.length - 1;
    });
    _saveSets();
  }

  // Open a set (simple: pick by index) with delete option
  void _openSetDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        // Use StatefulBuilder to update dialog UI after deletion
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Open Set', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: sets.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text('Set ${index + 1} (${sets[index].length} solves)'),
                      onTap: () {
                        setState(() {
                          currentSetIndex = index;
                          solves
                            ..clear()
                            ..addAll(sets[index]);
                        });
                        Navigator.of(context).pop();
                      },
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete Set',
                        onPressed: () async {
                          if (sets.length == 1) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('At least one set must remain.')),
                            );
                            return;
                          }
                          setState(() {
                            sets.removeAt(index);
                            if (currentSetIndex == index) {
                              currentSetIndex = 0;
                              solves
                                ..clear()
                                ..addAll(sets[0]);
                            } else if (currentSetIndex > index) {
                              currentSetIndex--;
                            }
                          });
                          setStateDialog(() {}); // Update dialog UI
                          await _saveSets();
                        },
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Add solve to current set and save
  void _addSolve(String time) {
    setState(() {
      solves.add(time);
      sets[currentSetIndex] = List<String>.from(solves);
    });
    _saveSets();
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
            _addSolve(_displayTime); // <-- use this instead of solves.add
          });
        }
      },
        
            child: Expanded(
              child: Center(
                child: Container(//timerArea
                  height: 300,
                  width: 300,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
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
                    //timer display
                    Text(
                      _displayTime,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'OpenRunde',
                      ),
                    ),
                    //state
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
                  ? Center(child: Text('No times yet', style: TextStyle(color: Colors.white54)))
                  : ListView.builder(

                      itemCount: solves.length,
                      itemBuilder: (context, index) {
                       return Text(
                            '${index + 1}: ${solves[index]}',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                            
                          
                        );
                      },
                    ),
            ),

    
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'open',
            onPressed: _openSetDialog,
            tooltip: 'Open Set',
            child: Icon(Icons.folder_open),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'new',
            onPressed: _newSet,
            tooltip: 'New Set',
            child: Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildStateText() {
    switch (timerState) {
      case 0:
        return Text('Ready?', style: TextStyle(fontSize: 24, color: Colors.white60));
      case 1:
        return Text('Set', style: TextStyle(fontSize: 24, color: Colors.white60));
      case 2:
        return Text('Go!', style: TextStyle(fontSize: 24, color: Colors.white60));
      default:
        return Text('Unknown State', style: TextStyle(fontSize: 24, color: Colors.white60));
    }
  }
}