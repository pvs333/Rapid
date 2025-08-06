import 'package:flutter/material.dart';

class StatsPage extends StatelessWidget{
  const StatsPage({super.key});



  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
        child: Text(
          'Stats Page',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}