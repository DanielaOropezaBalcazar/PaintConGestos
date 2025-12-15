import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/painting/painting_bloc.dart';
import '../bloc/painting/painting_event.dart';
import '../bloc/painting/painting_state.dart';

class ColorPaletteWidget extends StatelessWidget {
  const ColorPaletteWidget({super.key});

  static const List<Color> colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.black,
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaintingBloc, PaintingState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Colores:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: colors.length,
                itemBuilder: (context, index) {
                  final color = colors[index];
                  final isSelected = state.currentColor == color;
                  
                  return GestureDetector(
                    onTap: () {
                      context.read<PaintingBloc>().add(ChangeColor(color));
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.black : Colors.grey.shade300,
                          width: isSelected ? 3 : 1,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}