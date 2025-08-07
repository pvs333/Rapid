import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../solves_store.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  Map<DateTime, List<Map<String, String>>> _solvesByDate = {};
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, String>> _selectedSolves = [];

  @override
  void initState() {
    super.initState();
    SolvesStore().addListener(_onSolvesChanged);
    _loadAllSolves();
  }

  @override
  void dispose() {
    SolvesStore().removeListener(_onSolvesChanged);
    super.dispose();
  }

  void _onSolvesChanged() =>  _loadAllSolves();

  Future<void> _loadAllSolves() async {
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

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedSolves = _solvesByDate[_selectedDayOnly(selectedDay)] ?? [];
    });
  }

  Future<void> _deleteSolve(Map<String, String> solve) async {
    SolvesStore().deleteSolve(solve);
  }

  int _getStreak() {
    final days = _solvesByDate.keys.toList()..sort((a, b) => b.compareTo(a));
    if (days.isEmpty) return 0;
    int streak = 0;
    DateTime today = DateTime.now();
    DateTime current = DateTime(today.year, today.month, today.day);

    // If today has no solves, start from yesterday
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
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => _selectedDayOnly(_selectedDay ?? DateTime.now()) == _selectedDayOnly(day),
              eventLoader: (day) => _solvesByDate[_selectedDayOnly(day)] ?? [],
              calendarStyle: CalendarStyle(
                markerDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
              ),
              onDaySelected: _onDaySelected,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _selectedSolves.isEmpty
                  ? Center(child: Text('No solves for this day'))
                  : ListView.separated(
                      itemCount: _selectedSolves.length,
                      separatorBuilder: (_, __) => Divider(height: 1),
                      itemBuilder: (context, index) {
                        final solve = _selectedSolves[index];
                        return ListTile(
                          title: Text(
                            solve['time']!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'OpenRunde',
                            ),
                          ),
                          subtitle: Text(
                            DateTime.parse(solve['date']!)
                                .toLocal()
                                .toString()
                                .split('.')
                                .first,
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                            onPressed: () async {
                              await _deleteSolve(solve);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}