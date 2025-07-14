import 'package:flutter/material.dart';
import 'home_screen.dart';

void main() {
  runApp(MaterialApp(
    home: HomeScreen(),
    debugShowCheckedModeBanner: false,
    themeMode: ThemeMode.dark,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.light),
      useMaterial3: true,
    ),
    darkTheme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
      useMaterial3: true,
      scaffoldBackgroundColor: Color(0xFF181A20),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF23262F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
    ),
  ));
} 