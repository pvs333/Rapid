import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../solves_store.dart';
import '../pages/settingspage.dart'; // Add this import at the top


class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<DateTime, List<Map<String, String>>> _solvesByDate = {};
  final DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, String>> _selectedSolves = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    SolvesStore().addListener(_onSolvesChanged);
    _loadAllSolves();
  }

  @override
  void dispose() {
    _tabController.dispose();
    SolvesStore().removeListener(_onSolvesChanged);
    super.dispose();
  }

  void _onSolvesChanged() => _loadAllSolves();

  Future<void> _loadAllSolves() async {
    // Instead of file IO, just use SolvesStore().solves
    Map<DateTime, List<Map<String, String>>> solvesMap = {};
    for (var e in SolvesStore().solves) {
      final date = DateTime.parse(e['date'] as String);
      final day = DateTime(date.year, date.month, date.day);
      solvesMap.putIfAbsent(day, () => []);
      solvesMap[day]!.add({
        'time': e['time'] as String,
        'date': e['date'] as String,
      });
    }
    setState(() {
      _solvesByDate = solvesMap;
      _selectedDay = _focusedDay;
      _selectedSolves = _solvesByDate[_selectedDayOnly(_focusedDay)] ?? [];
    });
  }

  DateTime _selectedDayOnly(DateTime day) => DateTime(day.year, day.month, day.day);

  // --- Stats helpers ---
  double _parseTime(String time) {
    final parts = time.split(':');
    final min = int.parse(parts[0]);
    final secParts = parts[1].split('.');
    final sec = int.parse(secParts[0]);
    final hundredths = int.parse(secParts[1]);
    return min * 60 + sec + hundredths / 100.0;
  }

  double? _bestTime(List<Map<String, String>> solves) {
    if (solves.isEmpty) return null;
    return solves.map((s) => _parseTime(s['time']!)).reduce((a, b) => a < b ? a : b);
  }

  double? _averageTime(List<Map<String, String>> solves) {
    if (solves.isEmpty) return null;
    return solves.map((s) => _parseTime(s['time']!)).reduce((a, b) => a + b) / solves.length;
  }

  List<Map<String, String>> get _allSolves {
    return _solvesByDate.values.expand((l) => l).toList();
  }

  List<double> _getDayTimes(DateTime day) {
    return (_solvesByDate[_selectedDayOnly(day)] ?? []).map((s) => _parseTime(s['time']!)).toList();
  }

  List<double> _getLast7Averages() {
    final now = DateTime.now();
    List<double> avgs = [];
    for (int i = 6; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final times = _getDayTimes(day);
      avgs.add(times.isEmpty ? 0 : times.reduce((a, b) => a + b) / times.length);
    }
    return avgs;
  }

  String _formatSeconds(double? seconds) {
    if (seconds == null) return '--';
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return '${min.toString().padLeft(2, '0')}:${sec.toStringAsFixed(2).padLeft(5, '0')}';
  }

  int _getStreak() {
    final days = _solvesByDate.keys.toList()..sort((a, b) => b.compareTo(a));
    if (days.isEmpty) return 0;
    int streak = 0;
    DateTime today = DateTime.now();
    DateTime current = DateTime(today.year, today.month, today.day);

    if (!_solvesByDate.containsKey(current)) {
      current = current.subtract(Duration(days: 1));
    }

    for (final day in days) {
      if (current.difference(day).inDays == 0) {
        streak++;
        current = current.subtract(Duration(days: 1));
      } else if (current.difference(day).inDays > 0) {
        break;
      }
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // --- Stats Tab only ---
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView(
                    children: [
                      // --- Streak Row ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            "${_getStreak()} day streak",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatBox(
                            label: "Best Today",
                            value: _formatSeconds(_bestTime(_selectedSolves)),
                          ),
                          _StatBox(
                            label: "Best Ever",
                            value: _formatSeconds(_bestTime(_allSolves)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _StatBox(
                            label: "Avg Today",
                            value: _formatSeconds(_averageTime(_selectedSolves)),
                            
                          ),
                          _StatBox(
                            label: "Avg Ever",
                            value: _formatSeconds(_averageTime(_allSolves)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text("Today's Solves", style:  GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w900)),
                      // --- Today's Solves Graph ---
                      SizedBox(
                        height: 160,
                        child: _selectedSolves.length < 2
                            ? Center(child: Text('Not Enough Solves Today'))
                            : Padding(
                                padding: EdgeInsets.only(top:8, bottom: 8, right: 8),
                                child: ValueListenableBuilder<bool>(
                                  valueListenable: SettingsStore.detailedGraph,
                                  builder: (context, detailed, _) => LineChart(
                                    LineChartData(
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: _getDayTimes(_selectedDay ?? DateTime.now())
                                              .asMap()
                                              .entries
                                              .map((e) => FlSpot(e.key.toDouble(), e.value))
                                              .toList(),
                                          color: Theme.of(context).colorScheme.primary,
                                          barWidth: 3,
                                        ),
                                      ],
                                      titlesData: FlTitlesData(
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(showTitles: detailed, reservedSize: 40),
                                        ),
                                        bottomTitles: AxisTitles(
                                          sideTitles: SideTitles(showTitles: detailed, reservedSize: 28, interval: 1),
                                        ),
                                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: detailed)),
                                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: detailed)),
                                      ),
                                      gridData: FlGridData(show: detailed),
                                      borderData: FlBorderData(
                                        show: detailed,
                                        border: Border.all(color: detailed ? Theme.of(context).dividerColor : Colors.transparent),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 24),
                      Text("Last Week Avg", style:  GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w900)),
                      
                      // --- Last Week Avg Graph ---
                      SizedBox(
                        height: 160,
                        child: (() {
                          final now = DateTime.now();
                          int daysWithSolves = 0;
                          for (int i = 6; i >= 0; i--) {
                            final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
                            if ((_solvesByDate[_selectedDayOnly(day)] ?? []).isNotEmpty) {
                              daysWithSolves++;
                            }
                          }
                          if (daysWithSolves < 2) {
                            return Center(child: Text('Needs At Least 2 Days of Solves'));
                          }
                          return Padding(
                            padding: EdgeInsets.only(top:8, bottom: 8, right: 8),
                            child: ValueListenableBuilder<bool>(
                              valueListenable: SettingsStore.detailedGraph,
                              builder: (context, detailed, _) => LineChart(
                                LineChartData(
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: _getLast7Averages()
                                          .asMap()
                                          .entries
                                          .map((e) => FlSpot((e.key + 1).toDouble(), e.value))
                                          .toList(),
                                      color: Theme.of(context).colorScheme.secondary,
                                      barWidth: 3,
                                      dotData: FlDotData(show: true),
                                    ),
                                  ],
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(showTitles: detailed, reservedSize: 40),
                                    ),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: detailed,
                                        reservedSize: 28,
                                        interval: 1,
                                        getTitlesWidget: (value, meta) {
                                          if (!detailed || value < 1 || value > 7 || value % 1 != 0) return const SizedBox.shrink();
                                          return Padding(
                                            padding: EdgeInsets.only(
                                              left: value == 1 ? 8 : 0,
                                              right: value == 7 ? 8 : 0,
                                              top: 10,
                                            ),
                                            child: Text(
                                              value.toInt().toString(),
                                              style: Theme.of(context).textTheme.bodySmall,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: detailed)),
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: detailed)),
                                  ),
                                  borderData: FlBorderData(
                                    show: detailed,
                                    border: Border.all(color: detailed ? Theme.of(context).dividerColor : Colors.transparent),
                                  ),
                                  gridData: FlGridData(show: detailed),
                                  minX: 1,
                                  maxX: 7,
                                ),
                              ),
                            ),
                          );
                        })(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  const _StatBox({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(label, style:  GoogleFonts.montserrat( fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 24)),
        ],
      ),
    );
  }
}