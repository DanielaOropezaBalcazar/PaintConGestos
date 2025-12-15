import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'screens/main_menu.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    final cameras = await availableCameras();
    runApp(FacePaintApp(cameras: cameras));
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Error inicializando cámaras: $e')),
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
      home: MainMenu(cameras: cameras),
    );
  }
}