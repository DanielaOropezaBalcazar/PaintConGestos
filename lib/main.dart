import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'main_menu.dart';
import 'home_page.dart';
import 'painting_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    final cameras = await availableCameras();
    runApp(
      ChangeNotifierProvider(
        create: (context) => PaintingState(),
        child: FacePaintApp(cameras: cameras),
      ),
    );
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error: $e'),
          ),
        ),
      ),
    );
  }
}

class FacePaintApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  
  const FacePaintApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pintura con Gestos Faciales',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => MainMenu(cameras: cameras),
        '/paint': (context) => HomePage(cameras: cameras),
      },
    );
  }
}