import 'dart:ffi';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hoopster/Parabola.dart';
import 'package:hoopster/PermanentStorage.dart';
import 'package:hoopster/ShotChecker.dart';
import 'package:hoopster/Merged/detect_logic.dart';

import 'package:hoopster/statsObjects.dart';

import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import '../main.dart';
import 'home_screen.dart';


late int padSize;
int i = 0;

final _outputShapes = [];
late CameraImage _cameraImage;
bool isprocessing = false;
int counter = 0;
String lastSaved = "";
String asset = 'AssetsFolder\\detect.tflite';
bool saveimage = true;
late ByteData byteData;
int Hit = 0;
int Miss = 0;
var height;
var width;
const int INPUT_SIZE = 300;
int counterImage = 0;
late double scalex;
late double scaley;
List<List<double>> coorFinger = [];
bool StopModel = false;
int tap = 0;
List<DateTime> timesRecorded = [];
late DateTime time;
double conf = 0.5;
int ballClass = 38;

class CameraScreen extends StatefulWidget {
  double w;
  double h;
  final tfl.Interpreter interpreter;
  CameraScreen(
      {Key? key, required this.interpreter, required this.h, required this.w})
      : super(key: key);
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  
  _CameraAppState() {

  }

  String _videoPath = '';
  @override
  Widget build(BuildContext context) {
    
    
    return Scaffold(
        body: Stack(children: [
      Container(
        child: Column(
          children: [
            GestureDetector(
              child: SizedBox(child: TrackingWidget()),
              onTapDown: (TapDownDetails details) {
                var tapPosition = details.globalPosition;
                double x = tapPosition.dx;
                double y = tapPosition.dy;
                if (coorFinger.length > 4) {
                  coorFinger = [];
                }
                coorFinger.add([x, y]);
              },
            ),
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
                        color: Color.fromARGB(255, 0, 255, 0),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsets.fromLTRB((w / 3) - 65, 0, (w / 3) - 65, 0),
                      child: GestureDetector(
                        child: Container(
                          height: 80,
                          width: 80,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(basketButton),
                              fit: BoxFit.fill,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromARGB(80, 0, 0, 0),
                                spreadRadius: 1,
                                blurRadius: 5,
                              )
                            ],
                            color: Color.fromARGB(0, 255, 255, 255),
                            borderRadius: BorderRadius.all(
                              Radius.circular(30),
                            ),
                          ),
                        ),
                        onTap: () => {
                          
                          setState(() {
                          })
                        },
                        onDoubleTap: () => {
                          //Session s= Session(DateTime.now(), 10, 7);
                        },
                      ),
                    ),
                    Text(
                      Miss.toString(),
                      style: TextStyle(
                        fontFamily: "Dogica",
                        fontSize: 60,
                        color: Color.fromARGB(255, 255, 0, 0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ]));
  }
}






  

  



