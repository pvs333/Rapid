// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Rapid/pages/first_page.dart';
import 'package:Rapid/pages/homepage.dart';
import 'package:Rapid/pages/settingspage.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'solves_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SolvesStore().load();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: SettingsStore.themeMode,
      builder: (context, mode, _) {
        ThemeMode themeMode;
        switch (mode) {
          case AppThemeMode.light:
            themeMode = ThemeMode.light;
            break;
          case AppThemeMode.dark:
            themeMode = ThemeMode.dark;
            break;
          default:
            themeMode = ThemeMode.system;
        }
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          home: DynamicColorBuilder(
            builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
              return MaterialApp(
                theme: ThemeData(
                  useMaterial3: true,
                  colorScheme: lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.deepPurple),
                  textTheme: GoogleFonts.montserratTextTheme().copyWith(
                    bodyLarge: TextStyle(fontFamily: 'OpenRunde'),
                    bodyMedium: TextStyle(fontFamily: 'OpenRunde'),
                    bodySmall: TextStyle(fontFamily: 'OpenRunde'),
                  ).apply(
                    bodyColor: (lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.deepPurple)).onSurface,
                    displayColor: (lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.deepPurple)).onSurface,
                  ),
                  appBarTheme: AppBarTheme(
                    titleTextStyle: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: (lightDynamic ?? ColorScheme.fromSeed(seedColor: Colors.deepPurple)).onSurface,
                    ),
                    centerTitle: true,
                  ),
                ),
                darkTheme: ThemeData(
                  useMaterial3: true,
                  colorScheme: darkDynamic ?? ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
                  textTheme: GoogleFonts.montserratTextTheme().copyWith(
                    bodyLarge: TextStyle(fontFamily: 'OpenRunde'),
                    bodyMedium: TextStyle(fontFamily: 'OpenRunde'),
                    bodySmall: TextStyle(fontFamily: 'OpenRunde'),
                  ).apply(
                    bodyColor: (darkDynamic ?? ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark)).onSurface,
                    displayColor: (darkDynamic ?? ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark)).onSurface,
                  ),
                  appBarTheme: AppBarTheme(
                    titleTextStyle: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: (darkDynamic ?? ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark)).onSurface,
                    ),
                    centerTitle: true,
                  ),
                ),
                themeMode: themeMode, // <-- This line makes the theme dynamic
                home: FirstPage(),
              );
            },
          ),
          routes: {
            '/homepage': (context) => HomePage(),
            '/settingspage': (context) => SettingsPage(),
            '/firstpage': (context) => FirstPage(),
          },
        );
      },
    );
  }
}
