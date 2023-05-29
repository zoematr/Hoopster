import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoopster/PermanentStorage.dart';
import 'package:hoopster/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

late List<CameraDescription> cameras;

SharedPreferences? prefs;
List<Session> allSessions = [
  Session(DateTime.now(), 10, 3),
  Session(DateTime.now(), 2, 8)
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();
  if (!prefs!.containsKey("Session")) {
    await prefs!.setStringList("Session", <String>[]);
  }

  allSessions += getAll();
  print(allSessions);
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
      title: "Hoopster",
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(/*firstCamera*/),
    );
  }
}
