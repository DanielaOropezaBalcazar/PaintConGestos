import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';
import 'screens/main_menu.dart';
import 'bloc/theme/theme_bloc.dart';
import 'bloc/theme/theme_state.dart';
import 'bloc/camera/camera_bloc.dart';
import 'bloc/gesture/gesture_bloc.dart';
import 'bloc/painting/painting_bloc.dart';
import 'repositories/camera_repository.dart';
import 'repositories/gesture_repository.dart';

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
    final cameraRepository = CameraRepository();
    final gestureRepository = GestureRepository(
      colors: const [
        Colors.red,
        Colors.blue,
        Colors.green,
        Colors.yellow,
        Colors.purple,
        Colors.orange,
        Colors.pink,
        Colors.teal,
        Colors.black,
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>(
          create: (context) => ThemeBloc(),
        ),
        BlocProvider<CameraBloc>(
          create: (context) => CameraBloc(cameraRepository: cameraRepository),
        ),
        BlocProvider<GestureBloc>(
          create: (context) => GestureBloc(gestureRepository: gestureRepository),
        ),
        BlocProvider<PaintingBloc>(
          create: (context) => PaintingBloc(),
        ),
      ],
      child: BlocBuilder<ThemeBloc, ThemeState>(
        builder: (context, themeState) {
          return MaterialApp(
            title: 'Pintura con Gestos Faciales',
            theme: themeState.themeData,
            debugShowCheckedModeBanner: false,
            home: MainMenu(cameras: cameras),
          );
        },
      ),
    );
  }
}