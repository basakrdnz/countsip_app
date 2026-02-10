import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DualCameraWidget extends StatefulWidget {
  final Function(String mainPath, String pipPath) onCaptured;

  const DualCameraWidget({super.key, required this.onCaptured});

  @override
  State<DualCameraWidget> createState() => _DualCameraWidgetState();
}

class _DualCameraWidgetState extends State<DualCameraWidget> {
  CameraController? _backController;
  CameraController? _frontController;
  bool _isReady = false;
  bool _isCapturing = false;
  Offset _pipPosition = const Offset(20, 20);
  bool _swapCameras = false;

  @override
  void initState() {
    super.initState();
    _initializeCameras();
  }

  Future<void> _initializeCameras() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    final back = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back);
    final front = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.front);

    _backController = CameraController(back, ResolutionPreset.high, enableAudio: false);
    _frontController = CameraController(front, ResolutionPreset.medium, enableAudio: false);

    await Future.wait([
      _backController!.initialize(),
      _frontController!.initialize(),
    ]);

    if (mounted) {
      setState(() => _isReady = true);
    }
  }

  @override
  void dispose() {
    _backController?.dispose();
    _frontController?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      final backFile = await _backController!.takePicture();
      final frontFile = await _frontController!.takePicture();
      
      widget.onCaptured(backFile.path, frontFile.path);
    } catch (e) {
      debugPrint('Capture error: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) return const Center(child: CircularProgressIndicator());

    final mainController = _swapCameras ? _frontController : _backController;
    final pipController = _swapCameras ? _backController : _frontController;

    return Stack(
      children: [
        // Main Camera
        Positioned.fill(
          child: CameraPreview(mainController!),
        ),

        // PIP Camera (Draggable)
        Positioned(
          right: _pipPosition.dx,
          top: _pipPosition.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _pipPosition += details.delta;
              });
            },
            child: Container(
              width: 120,
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFF8902), width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CameraPreview(pipController!),
              ),
            ),
          ),
        ),

        // Controls
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () => setState(() => _swapCameras = !_swapCameras),
                icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 30),
              ),
              GestureDetector(
                onTap: _capture,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                  ),
                  child: Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
