import 'dart:ffi';
import 'dart:math';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

import '../main.dart';
import 'home_screen.dart';

int i = 0;
late CameraImage _cameraImage;
int counter = 0;
String lastSaved = "";
int Hit = 0;
int Miss = 0;

class CameraApp extends StatefulWidget {
  const CameraApp({Key? key}) : super(key: key);

  @override
  State<CameraApp> createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  late CameraController controller;
  late Future<void> _initializeControllerFuture;
  String _videoPath = '';

  @override
  void initState() {
    super.initState();
    controller = CameraController(
      cameras[1],
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = controller.initialize().then((_) {
      controller.startImageStream((image) {
        _cameraImage = image;
        processCameraFrame(image); // Process each camera frame
      });

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

    loadModel(); // Load the TFLite model
  }

  void loadModel() async {
    final interpreter =
        await tfl.Interpreter.fromAsset('assets/your_model.tflite');
  }

  Future<void> processCameraFrame(CameraImage image) async {
    try {
      // Convert the CameraImage to a byte buffer
      Float32List convertedImage = convertCameraImage(image);

      // Create an instance of interpreter
      final interpreter =
          await tfl.Interpreter.fromAsset('Assets/model.tflite');

      // Define the number of results you expect from the model
      const int numResults = 10;

      // Create output tensor. Assuming model has single output of shape [1, numResults]
      var output = List.filled(1 * numResults, 0).reshape([1, numResults]);

      // Run inference on the frame
      interpreter.runForMultipleInputs(convertedImage, {0: output});

      // Process the inference results
      processInferenceResults(output);
    } catch (e) {
      print('Failed to run model on frame: $e');
    }
  }

  Float32List convertCameraImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int? uvPixelStride = image.planes[1].bytesPerPixel;

    final Float32List convertedImage = Float32List(width * height * 3);

    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final int uvIndex =
            uvPixelStride! * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int index = y * width + x;

        final int yValue = image.planes[0].bytes[index];
        final int uValue = image.planes[1].bytes[uvIndex];
        final int vValue = image.planes[2].bytes[uvIndex];

        final color =
            yuv2rgb(yValue, uValue, vValue); //Assuming yuv2rgb returns a Color
        convertedImage[index * 3 + 0] = 255.0;
        convertedImage[index * 3 + 1] = 255.0;
        convertedImage[index * 3 + 2] = 255.0;
      }
    }

    return convertedImage;
  }

  void processInferenceResults(List<dynamic> output) {
    // Process the inference output to get the labels and their coordinates
    List<Map<String, dynamic>> labels = [];
    for (dynamic label in output) {
      String text = label['label'];
      double confidence = label['confidence'];
      Map<String, dynamic> coordinates = label['rect'];

      labels.add({
        'text': text,
        'confidence': confidence,
        'coordinates': coordinates,
      });
    }

    // Do something with the labels and their coordinates
    // ...

    // Example: Print the labels
    for (var label in labels) {
      print('Label: ${label['text']}');
      print('Confidence: ${label['confidence']}');
      print('Coordinates: ${label['coordinates']}');
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _onRecordButtonPressed() async {
    try {
      if (controller.value.isRecordingVideo) {
        final path = await controller.stopVideoRecording();
        setState(() {
          _videoPath = path as String;
        });

        //processVideo(
        //    _videoPath); // Pass the video path to the processing function
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
    int _1 = Random().nextInt(20);
    int _2 = Random().nextInt(20);
    DateTime n = DateTime.now();
    setState(() {
      // allSessions.add(Session(n, _1, _2));
      // lView = globalUpdate();
    });

    if (_cameraImage != null) {
      Uint8List colored = Uint8List(_cameraImage.planes[0].bytes.length * 3);
      print("doing");
      int b = 0;

      img.Image image = convertCameraImage(_cameraImage);
      img.Image Rimage = img.copyRotate(image, 90);
      _saveImage(Rimage.data);

      // Convert the image to RGB format using image package
      // img.Image image = img.Image.fromBytes(
      //   _cameraImage.width,
      //   _cameraImage.height,
      //   _cameraImage.planes[0].bytes,
      //   format: img.Format.yuv420,
      // );
      // img.Image Rimage = img.copyRotate(image, 90);
      // _saveImage(Rimage.getBytes(format: img.Format.rgb));

      // Run inference on the converted image
      List<dynamic>? output = await Tflite.runModelOnBinary(
        binary: Rimage.getBytes(format: img.Format.rgb),
      );

      // Process the inference results
      processInferenceResults(output!);
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
      body: Container(
        child: Column(
          children: [
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
                          capture(),
                          setState(() {
                            Miss++;
                            Hit++;
                          })
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
    );
  }
}

Uint8List yuv2rgb(int y, int u, int v) {
  double yd = y.toDouble();
  double ud = u.toDouble() - 128.0;
  double vd = v.toDouble() - 128.0;

  double r = yd + 1.402 * vd;
  double g = yd - 0.344136 * ud - 0.714136 * vd;
  double b = yd + 1.772 * ud;

  r = r.clamp(0, 255).roundToDouble();
  g = g.clamp(0, 255).roundToDouble();
  b = b.clamp(0, 255).roundToDouble();

  return Uint8List.fromList([r.toInt(), g.toInt(), b.toInt()]);
}
