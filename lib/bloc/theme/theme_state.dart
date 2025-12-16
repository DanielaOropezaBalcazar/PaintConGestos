import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class ThemeState extends Equatable {
  const ThemeState();

  ThemeData get themeData;

  @override
  List<Object> get props => [themeData];
}

class LightTheme extends ThemeState {
  @override
  ThemeData get themeData => ThemeData(
    primarySwatch: Colors.purple,
    useMaterial3: true,
    fontFamily: 'Roboto',
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF9F7FC),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromARGB(255, 198, 169, 244),
      foregroundColor: Colors.black87,
    ),
  );
}

class DarkTheme extends ThemeState {
  @override
  ThemeData get themeData => ThemeData(
    primarySwatch: Colors.purple,
    useMaterial3: true,
    fontFamily: 'Roboto',
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1B1822), // color del canvas, oscuro pero neutro tirando a moradito
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromARGB(255, 50, 43, 68), // moradito asi como opaco oscurito
      // backgroundColor: Color.fromARGB(255, 48, 37, 75), // mas morado, mas intenso
      foregroundColor: Colors.white, // blanco
    ),
  );
}
