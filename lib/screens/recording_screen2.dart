import 'dart:async';
import 'dart:ffi';
import 'dart:math';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hoopster/PermanentStorage.dart';
import 'package:hoopster/statsObjects.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';

import '../main.dart';
import 'home_screen.dart';
import 'dart:isolate';

late Isolate isolate;
late ReceivePort _receivePort;
SendPort? _sendPort;

int i = 0;
late CameraImage _cameraImage;
int counter = 0;
String lastSaved = "";
int Hit = 0;
int Miss = 0;
var height;
var width;

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
      cameras.last,
      ResolutionPreset.medium,
    );

    // Initiate the loading of the model
    loadModel().then((interpreter) {
      // Model has been loaded at this point
      _initializeControllerFuture = controller.initialize().then((_) {
        controller.startImageStream((image) {
          _cameraFrameProcessing(image, interpreter);
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
    });
  }

  //void mainHandler(dynamic data, SendPort isolateSendPort) {}

  //void isolateHandler(
  //  dynamic data, SendPort mainSendPort, SendErrorFunction onSendError) {}

  void _cameraFrameProcessing(
      CameraImage image, tfl.Interpreter interpreter) async {
    setState(() {
      _cameraImage = image;
    });
    // Worker W = Worker();
    //Isolate.run(()async {processCameraFrame(image,interpreter);});7
    //_isolate.pause();
    _receivePort = ReceivePort();
    _sendPort = await _receivePort.first;
    isolate = await Isolate.spawn(_isolateHandler, _receivePort.sendPort);
    _sendToIsolate({'image': image, 'interpreter': interpreter});
  }

  void _sendToIsolate(Map<String, dynamic> data) async {
    // Create the isolate the first time that this function is called.
    if (isolate == null) {}

    _sendPort!.send(data);
  }

  void _isolateHandler(SendPort sendPort) {
    print("3");
    final port = ReceivePort();
    sendPort.send(port.sendPort);
    print("2");

    port.listen((message) {
      print("4");
      CameraImage image = message['image'];
      tfl.Interpreter interpreter = message['interpreter'];
      processCameraFrame(image,
          interpreter); // Assuming processCameraFrame is a static function
    });
    print("4");
  }

  /* FutureOr<void> startModel(CameraImage im, tfl.Interpreter interpreter_){
    processCameraFrame(im,interpreter_);
  }*/

  Future<tfl.Interpreter> loadModel() async {
    return tfl.Interpreter.fromAsset('Assets/model.tflite');
  }

  Future<void> processCameraFrame(
      CameraImage image, tfl.Interpreter interpreter) async {
    try {
      // Convert the CameraImage to a byte buffer
      Float32List convertedImage = convertCameraImage(image);

      // Create output tensor. Assuming model has a single output
      var outputshape = interpreter.getOutputTensor(0).shape;
      var output = List.generate(
          1,
          (_) => List.generate(
              13,
              (_) => List.generate(
                  13, (_) => List.generate(35, (_) => 0 as dynamic))));

      // Create input tensor with the desired shape
      var inputShape = interpreter.getInputTensor(0).shape;
      //print(inputShape);
      //var inputShape = [1, 13, 13, 35];
      var inputTensor = <List<List<List<dynamic>>>>[
        List.generate(inputShape[1], (_) {
          return List.generate(inputShape[2], (_) {
            return List.generate(inputShape[3], (_) {
              return 0.0; // Placeholder value, modify this according to your needs
            });
          });
        })
      ];

      // Copy the convertedImage data into the inputTensor
// Copy the convertedImage data into the inputTensor
      for (int i = 0; i < convertedImage.length; i++) {
        int index = i;
        int c = index % 3;
        index = index ~/ 3;
        int x = index % 416;
        index = index ~/ 416;
        int y = index;

        inputTensor[0][y][x][c] = convertedImage[i];
      }

      // Run inference on the frame
      interpreter.run(inputTensor, {0: output});

      // Process the inference results
      //print("here2, line 120");
      processInferenceResults(output);
    } catch (e) {
      print('Failed to run model on frame: $e');
    }
  }

  Float32List convertCameraImage(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int? uvPixelStride = image.planes[1].bytesPerPixel;

    // Create an Image buffer
    img.Image imago = img.Image(width, height);

    for (int x = 0; x < width; x++) {
      for (int y = 0; y < height; y++) {
        final int uvIndex =
            uvPixelStride! * (x / 2).floor() + uvRowStride * (y / 2).floor();
        final int index = y * width + x;

        final int yValue = image.planes[0].bytes[index];
        final int uValue = image.planes[1].bytes[uvIndex];
        final int vValue = image.planes[2].bytes[uvIndex];

        List rgbColor = yuv2rgb(yValue, uValue, vValue);
        // Set the pixel color
        imago.setPixelRgba(x, y, rgbColor[0], rgbColor[1], rgbColor[2]);
      }
    }

    // Resize the image to 416x416
    img.Image resizedImage = img.copyResize(imago, width: 416, height: 416);

    Float32List modelInput = Float32List(1 * 416 * 416 * 3);

    // Copy the resized RGB image data into the model input
    int pixelIndex = 0;
    for (int i = 0; i < 416; i++) {
      for (int j = 0; j < 416; j++) {
        int pixel = resizedImage.getPixel(i, j);

        modelInput[pixelIndex] = img.getRed(pixel) / 255.0;
        modelInput[pixelIndex + 1] = img.getGreen(pixel) / 255.0;
        modelInput[pixelIndex + 2] = img.getBlue(pixel) / 255.0;
        pixelIndex += 3;
      }
    }

    // Now you can use modelInput as the input to your model
    return modelInput;
  }

  void processInferenceResults(List<List<List<List<dynamic>>>> output) {
    // Assuming the output is a 4D tensor with dimensions [1, 13, 13, 35]

    for (int i = 0; i < output.length; i++) {
      // Looping through dimension 1
      for (int j = 0; j < output[i].length; j++) {
        // Looping through dimension 2
        for (int k = 0; k < output[i][j].length; k++) {
          // Looping through dimension 3
          for (int l = 0; l < output[i][j][k].length; l++) {
            // Looping through dimension 4
            // Perform processing on each element at output[i][j][k][l]
            var element = output[i][j][k][l];
            print(element);
            // Based on your TensorFlow model's output, you will have to decide what kind of processing is required here.
          }
        }
      }
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
        //await controller.startVideoRecording();
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
      int b = 0;
      img.Image image = _cameraImage as img.Image;

      var input = [1, 13, 13, 3];
      //img.Image image = convertCameraImage(_cameraImage);
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

      // Process the inference results
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
                          //capture(),
                          setState(() {
                            Miss++;
                            Hit++;
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
