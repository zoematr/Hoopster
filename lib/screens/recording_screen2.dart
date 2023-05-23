import 'dart:ffi';

import 'package:camera/camera.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hoopster/main.dart';
import 'package:hoopster/screens/home_screen.dart';
//import 'package:opencv_4/opencv_4.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
//import 'package:get/get.dart';
//import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
//import 'package:flutter_image/flutter_image.dart' as flImage;

//late List<CameraDescription> _cameras;
int i = 0;
late CameraImage _cameraImage;
int counter = 0;
String lastSaved = "";
int Hit = 0;
int Miss = 0;

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
  void processVideo(String videoPath) {
    //this badboy is gonna handle our video editing
    print('Video path: $videoPath');
  }

  @override
  void initState() {
    super.initState();
    controller = CameraController(
      cameras[1],
      ResolutionPreset.max,
    );

    //controller.lockCaptureOrientation(DeviceOrientation.landscapeLeft);
    _initializeControllerFuture = controller.initialize().then((_) {
      controller
          .startImageStream((image) => {/*print("eo")*/ _cameraImage = image});

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

        processVideo(
            _videoPath); // Pass the video path to the processing function
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

  //void startStreaming() {}

  //void save(List<int> _imageBytes){}
  Future<void> _saveImage(List<int> _imageBytes) async {
    counter++;
    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/frame${counter}.png';
    lastSaved = imagePath;
    final imageFile = File(imagePath);
    await imageFile.writeAsBytes(_imageBytes);
    print('Image saved to: $imagePath');
  }

  void capture() async {
    if (_cameraImage != null) {
      Uint8List colored = Uint8List(_cameraImage.planes[0].bytes.length * 3);
      print("doing");
      int b = 0;
      //int y = 0;
      /*for (int x in _cameraImage.planes[0].bytes) {
        //String s =${_cameraImage.planes[0].bytes[x]}${_cameraImage.planes[1].bytes[x]}${_cameraImage.planes[2].bytes[x]}";
        //int i = int.parse(s);
        //print("doing");
        //colored[x] = i;
        for (int y = 0; y < 3; y++) {
          colored[b] = _cameraImage.planes[y].bytes[x];
          b++;
          //b++;
          //if (_cameraImage.planes[0].bytes.length % b == 0) {
          //y++;
          //}
          //colored[b - 1] = _cameraImage.planes[y].bytes[x];
        }
      }*/
      //print("done");
      //print(colored.length);
      // List<int> planes = _cameraImage.planes[0].bytes +
      //   _cameraImage.planes[1].bytes +
      // _cameraImage.planes[2].bytes;
      //print(planes.length);
      img.Image image = img.Image.fromBytes(
        _cameraImage.width,
        _cameraImage.height,
        _cameraImage.planes[0]
            .bytes, //_cameraImage.planes[0].bytes+_cameraImage.planes[1].bytes+_cameraImage.planes[2].bytes,
        format: img.Format.luminance,
      );
      img.Image Rimage = img.copyRotate(image, 90);
      _saveImage(Rimage.data);

      //print(_cameraImage.planes.length); /data/user/0/com.example.hoopster/app_flutter/frame1.png
      //print(image.height);
      Uint8List list = Uint8List.fromList(img.encodePng(Rimage));
      //print(list.length);
      await ImageGallerySaver.saveImage(list);
      //_imageList.add(list);
      //_imageList.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container(
        color: Color.fromARGB(255, 255, 0, 0),
      );
    }
    return Scaffold(
      /*appBar: AppBar(
        title: Text("Recording Screen"),
      ),*/
      body: Container(
        child: Column(children: [
          SizedBox(child: CameraPreview(controller)),
          Expanded(
              child: Container(
                  color: Color.fromARGB(255, 93, 70, 94),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        Hit.toString(),
                        style: TextStyle(
                            fontFamily: "Dogica",
                            fontSize: 60,
                            color: Color.fromARGB(255, 0, 255, 0)),
                      ),
                      Padding(
                          padding: EdgeInsets.fromLTRB(
                              (w / 3) - 65, 0, (w / 3) - 65, 0),
                          child: GestureDetector(
                              child: Container(
                                  height: 80,
                                  width: 80,
                                  decoration: BoxDecoration(
                                      image: DecorationImage(
                                          image: AssetImage(basketButton),
                                          fit: BoxFit.fill),
                                      boxShadow: [
                                        BoxShadow(
                                            color: Color.fromARGB(80, 0, 0, 0),
                                            spreadRadius: 1,
                                            blurRadius: 5)
                                      ],
                                      color: Color.fromARGB(0, 255, 255, 255),
                                      borderRadius: BorderRadius.all(
                                          Radius.circular(30)))),
                              onTap: () => {
                                    capture(),
                                    setState(() {
                                      Miss++;
                                      Hit++;
                                    })
                                  })),
                      Text(
                        Miss.toString(),
                        style: TextStyle(
                            fontFamily: "Dogica",
                            fontSize: 60,
                            color: Color.fromARGB(255, 255, 0, 0)),
                      ),
                    ],
                  )))
        ]),
      ),
    );
    // return Scaffold(body: CameraPreview(controller));
  }
}
