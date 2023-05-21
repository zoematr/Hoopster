import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoopster/screens/home_screen.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  // Step 3
  runApp(MyApp());

  //final firstCamera = cameras.first;
}

class MyApp extends StatelessWidget {
  //final firstCamera;
  MyApp(/*List<CameraDescription> this.firstCamera*/);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hoopster',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(/*firstCamera*/),
    );
  }
}
