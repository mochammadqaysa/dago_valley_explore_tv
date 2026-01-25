// tiny_planet_widget.dart (atau di dalam file yang sama)
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class TinyPlanetWidget extends StatefulWidget {
  final ImageProvider imageProvider;
  final double rotation;
  final double scale; // <--- Parameter Baru

  const TinyPlanetWidget({
    Key? key,
    required this.imageProvider,
    this.rotation = 0.0,
    this.scale = 0.3, // Default scale planet
  }) : super(key: key);

  @override
  State<TinyPlanetWidget> createState() => _TinyPlanetWidgetState();
}

class _TinyPlanetWidgetState extends State<TinyPlanetWidget> {
  ui.FragmentProgram? _program;
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _loadShader();
    _loadImage();
  }

  // ... (Bagian _loadShader dan _loadImage sama seperti sebelumnya) ...
  Future<void> _loadShader() async {
    final program = await ui.FragmentProgram.fromAsset(
      'assets/shaders/tiny_planet.frag',
    );
    setState(() => _program = program);
  }

  Future<void> _loadImage() async {
    final imageStream = widget.imageProvider.resolve(
      const ImageConfiguration(),
    );
    imageStream.addListener(
      ImageStreamListener((info, _) {
        if (mounted) setState(() => _image = info.image);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_program == null || _image == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return CustomPaint(
      painter: TinyPlanetPainter(
        _program!,
        _image!,
        widget.rotation,
        widget.scale, // <--- TAMBAHKAN INI (widget.scale)
      ),
      child: Container(),
    );
  }
}

class TinyPlanetPainter extends CustomPainter {
  final ui.FragmentProgram program;
  final ui.Image image;
  final double rotation;
  final double scale; // <--- Terima Scale

  TinyPlanetPainter(this.program, this.image, this.rotation, this.scale);

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();

    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, scale); // Input Scale ke index 2 (sesuai GLSL)
    shader.setFloat(3, rotation); // Input Rotation ke index 3

    shader.setImageSampler(0, image);

    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant TinyPlanetPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.scale != scale ||
        oldDelegate.image != image;
  }
}
