import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hoopster/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  runApp(MyApp(firstCamera));
}

class MyApp extends StatelessWidget {
  final firstCamera;
  MyApp(CameraDescription this.firstCamera);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hoopster',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(firstCamera),
    );
  }
}
