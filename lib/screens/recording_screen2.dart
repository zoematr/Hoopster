import 'package:camera/camera.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoopster/main.dart';

//late List<CameraDescription> _cameras;
int i = 0;

/*Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _cameras = await availableCameras();
  runApp(const CameraApp());
}*/

/// CameraApp is the Main Application.
class CameraApp extends StatefulWidget {
  //final List<CameraDescription> camera_;

  /// Default Constructor
  const CameraApp(/*this.camera_*/ {super.key});

  @override
  State<CameraApp> createState() => _CameraAppState(/*this.camera_*/);
}

class _CameraAppState extends State<CameraApp> {
  late CameraController controller;
  late Future<void> _initializeControllerFuture;
  String _videoPath = '';
  //List<CameraDescription> camera_;

  _CameraAppState(/*this.camera_*/) {
    //initState();
  }
  @override
  void initState() {
    super.initState();
    controller = CameraController(cameras[0], ResolutionPreset.max);
    controller.lockCaptureOrientation(DeviceOrientation.landscapeLeft);
    _initializeControllerFuture = controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
  }

  Future<void> _onRecordButtonPressed() async {
    try {
      if (controller.value.isRecordingVideo) {
        final path = await controller.stopVideoRecording();
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
        print(path);
        await controller.startVideoRecording();
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> stopVideoRecording() async {
    if (!controller.value.isInitialized) {
      return;
    }

    if (!controller.value.isRecordingVideo) {
      return;
    }

    try {
      await controller.stopVideoRecording();
    } on CameraException catch (e) {
      print('Error: ${e.code}\n${e.description}');
      return;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container(
        color: Color.fromARGB(255, 255, 0, 0),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text("Recording Screen"),
      ),
      body: CameraPreview(controller),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.stop),
        onPressed: () => {
          if (i % 2 == 0)
            {_onRecordButtonPressed()}
          else
            {stopVideoRecording()},
          i++
        },
      ),
    );
    // return Scaffold(body: CameraPreview(controller));
  }
}
