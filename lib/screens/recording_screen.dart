import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class RecordingScreen extends StatefulWidget {
  final CameraDescription camera;

  const RecordingScreen({
    Key? key,
    required this.camera,
  }) : super(key: key);

  @override
  _RecordingScreenState createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  String _videoPath = '';

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.high);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _cameraPreviewWidget() {
    if (_controller == null || !_controller.value.isInitialized) {
      return Container();
    }
    return AspectRatio(
      aspectRatio: _controller.value.aspectRatio,
      child: CameraPreview(_controller),
    );
  }

  Future<void> _onRecordButtonPressed() async {
    try {
      if (_controller.value.isRecordingVideo) {
        final path = await _controller.stopVideoRecording();
        setState(() {
          _videoPath = path as String;
        });
      } else {
        await _initializeControllerFuture;
        final now = DateTime.now();
        final formattedDate =
            '${now.year}-${now.month}-${now.day} ${now.hour}-${now.minute}-${now.second}';
        final fileName = 'hoopster_${formattedDate}.mp4';
        final path = '${Directory.systemTemp.path}/$fileName';
        await _controller.startVideoRecording();
      }
    } catch (e) {
      print(e);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Recording Screen"),
      ),
      body: _buildCameraPreview(), /*Column(
        children: [
          Expanded(
            child: Center(
              child: _cameraPreviewWidget(),
            ),
          ),
          if (_videoPath.isNotEmpty)
            Expanded(
              child: Center(
                child:
                    VideoPlayer(VideoPlayerController.file(File(_videoPath))),
              ),
            ),
        ],
      ),*/
      floatingActionButton: FloatingActionButton(
        child: Icon(_controller.value.isRecordingVideo
            ? Icons.stop
            : Icons.fiber_manual_record),
        onPressed: _onRecordButtonPressed,
      ),
    );
  }
  Widget _buildCameraPreview() {
  if (_controller == null || !_controller.value.isInitialized) {
    return Container();
  }
  return AspectRatio(
    aspectRatio: _controller.value.aspectRatio,
    child: CameraPreview(_controller),
  );
}

}



