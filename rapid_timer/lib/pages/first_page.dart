import 'package:flutter/material.dart';
import 'package:rapid_timer/pages/calendarpage.dart';
import 'package:rapid_timer/pages/homepage.dart';
import 'package:rapid_timer/pages/settingspage.dart';
import 'package:rapid_timer/pages/statspage.dart';

class FirstPage extends StatefulWidget{
  const FirstPage({super.key});

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  int selectedIndex = 0;

  final List pages =[
    HomePage(),
    StatsPage(),
    CalendarPage(),
    SettingsPage(),
  ];

  void navigateBar(int index) {
    setState(() {
      selectedIndex = index;
    });
  } 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Rapid", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 32)),
        centerTitle: true,
      ),
      
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: navigateBar,
        type : BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: selectedIndex == 0 ? Icon(Icons.timer) : Icon(Icons.timer_outlined),
            label: 'Timer',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon:  selectedIndex == 2 ? Icon(Icons.calendar_month) : Icon(Icons.calendar_month_outlined),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon:  selectedIndex == 3 ? Icon(Icons.settings) : Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
        ),
    );
  }
}