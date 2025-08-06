import 'package:flutter/material.dart';
import 'package:rapid_timer/pages/homepage.dart';
import 'package:rapid_timer/pages/settingspage.dart';
import 'package:rapid_timer/pages/statspage.dart';

class FirstPage extends StatefulWidget{
  FirstPage({super.key});

  @override
  State<FirstPage> createState() => _FirstPageState();
}

class _FirstPageState extends State<FirstPage> {
  int selectedIndex = 0;

  final List pages =[
    HomePage(),
    StatsPage(),
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
        title: Text("Rapid", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: navigateBar,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.timer),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        ),
    );
  }
}