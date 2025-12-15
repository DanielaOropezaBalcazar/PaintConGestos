import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/camera/camera_bloc.dart';
import '../bloc/gesture/gesture_bloc.dart';
import '../bloc/painting/painting_bloc.dart';
import '../repositories/camera_repository.dart';
import '../repositories/gesture_repository.dart';
import 'painting_screen.dart';

class MainMenu extends StatelessWidget {
  final List<CameraDescription> cameras;
  
  const MainMenu({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color.fromARGB(199, 46, 43, 121),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🎨 PINTURA CON GESTOS FACIALES',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 30),
                
                _buildMenuButton(
                  icon: Icons.palette,
                  text: 'Ingresar',
                  color: const Color.fromARGB(255, 206, 134, 172),
                  onPressed: () {
                    // Navegar con BLoCs
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => _buildPaintingScreenWithBlocs(),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                
                _buildMenuButton(
                  icon: Icons.help_outline,
                  text: 'Tutorial',
                  color: const Color.fromARGB(255, 206, 134, 172),
                  onPressed: () {
                    _showTutorial(context);
                  },
                ),
                
                const SizedBox(height: 20),
                
                _buildMenuButton(
                  icon: Icons.exit_to_app,
                  text: 'Salir',
                  color: const Color.fromARGB(255, 206, 134, 172),
                  onPressed: () {
                    _confirmExit(context);
                  },
                ),
                
                const SizedBox(height: 30),
                const Text(
                  '© 2025 Pintura con Gestos',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Crea la pantalla de pintura con todos los BLoCs
  Widget _buildPaintingScreenWithBlocs() {
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
      child: FaceToGestureListener(
        child: GestureToPaintingListener(
          child: PaintingScreen(cameras: cameras),
        ),
      ),
    );
  }

  Widget _buildMenuButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 250,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          elevation: 5,
          shadowColor: color.withOpacity(0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 15),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTutorial(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(255, 46, 43, 121),
        title: const Row(
          children: [
            Icon(Icons.help, color: Color.fromARGB(255, 206, 134, 172)),
            SizedBox(width: 10),
            Text('📚 TUTORIAL', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTutorialStep(
                '1️⃣ PREPARACIÓN',
                '• Asegura buena iluminación\n• Colócate a 30-50cm de la cámara\n• Mantén el rostro centrado',
              ),
              const SizedBox(height: 15),
              _buildTutorialStep(
                '🎨 PINTAR',
                'SONRÍE para activar el pincel\nMUEVE LA CABEZA para dibujar',
              ),
              const SizedBox(height: 15),
              _buildTutorialStep(
                '🔄 CAMBIAR MODO',
                'PARPADEA RÁPIDO para alternar entre:\n• Pincel (azul) ↔ Goma (rojo)',
              ),
              const SizedBox(height: 15),
              _buildTutorialStep(
                '🎨 CAMBIAR COLOR',
                'INCLINA LA CABEZA A LA DERECHA\npara cambiar entre colores',
              ),
              const SizedBox(height: 15),
              _buildTutorialStep(
                '↩️ DESHACER',
                'INCLINA LA CABEZA A LA IZQUIERDA\npara eliminar el último trazo',
              ),
              const SizedBox(height: 15),
              _buildTutorialStep(
                '🗑️ LIMPIAR TODO',
                'MIRA HACIA ARRIBA\npara borrar todo el lienzo',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Entendido',
              style: TextStyle(color: Color.fromARGB(255, 206, 134, 172)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialStep(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 206, 134, 172),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.pink),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            content,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color.fromARGB(199, 46, 43, 121),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Color.fromARGB(255, 206, 134, 172)),
            SizedBox(width: 10),
            Text('¿Salir de la app?', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que quieres salir?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 206, 134, 172),
            ),
            child: const Text('SALIR'),
          ),
        ],
      ),
    );
  }
}