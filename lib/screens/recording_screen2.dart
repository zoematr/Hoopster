import 'dart:ffi';
import 'dart:math';
import 'package:camera/camera.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hoopster/PermanentStorage.dart';
import 'package:hoopster/statsObjects.dart';
import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:tflite_flutter_helper/tflite_flutter_helper.dart';
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
var height;
var width;
const int INPUT_SIZE = 416;
//late tfl.IsolateInterpreter isolate;
late tfl.Interpreter interpreter;

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
      ResolutionPreset.low,
    );

    loadModel().then((interpreter) {
      //isolate = tfl.IsolateInterpreter(address: interpreter.address);
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

  void _cameraFrameProcessing(CameraImage image, tfl.Interpreter interpreter) {
    _cameraImage = image;
    processCameraFrame(image, interpreter); // Process each camera frame
  }

  Future<tfl.Interpreter> loadModel() async {
    return tfl.Interpreter.fromAsset(
      'model.tflite',
      options: tfl.InterpreterOptions()..threads = 4,
    );
  }

  Future<void> processCameraFrame(
      CameraImage image, tfl.Interpreter interpreter) async {
    try {
      img.Image imago = ImageUtils.convertYUV420ToImage(image);
      imago = resizeImageTo32(imago);
      var tensorImage = TensorImage.fromImage(imago);
      tensorImage = ImageProcessorBuilder()
          .add(ResizeOp(416, 416, ResizeMethod.NEAREST_NEIGHBOUR))
          .add(NormalizeOp(0, 255))
          .build()
          .process(tensorImage);

      var outputShape = interpreter.getOutputTensor(0).shape;
      print('outputShape');
      var outputType = interpreter.getOutputTensor(0).type;
      print('outputtype');
      var outputBuffer = TensorBuffer.createFixedSize(outputShape, outputType);
      print('outputbuffer');
      interpreter.run(tensorImage.buffer, outputBuffer.getBuffer());
      print('ran interpreter');
      var outputResult = outputBuffer.getDoubleList();
      print(outputResult);

      // Process the inference results
      //print("here2, line 120");
      //processInferenceResults(output);
    } catch (e) {
      print('Failed to run model on frame: $e');
    }
  }

  Float32List convertCameraImage(CameraImage image) {
    try {
      var width = image.width;
      var height = image.height;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int? uvPixelStride = image.planes[1].bytesPerPixel;

      img.Image imago = img.Image(height: height, width: width);
      for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
          final int uvIndex =
              uvPixelStride! * (x / 2).floor() + uvRowStride * (y / 2).floor();
          final int index = y * width + x;
          final int yValue = image.planes[0].bytes[index];
          final int uValue = image.planes[1].bytes[uvIndex];
          final int vValue = image.planes[2].bytes[uvIndex];
          List rgbColor = [1, 2, 4];
          imago.setPixelRgba(x, y, rgbColor[0], rgbColor[1], rgbColor[2], 1);
        }
      }
      img.Image resizedImage = img.copyResize(imago, width: 416, height: 416);
      Float32List modelInput = Float32List(1 * 416 * 416 * 3);

      int pixelIndex = 0;
      for (int i = 0; i < 416; i++) {
        for (int j = 0; j < 416; j++) {
          var pixel = resizedImage.getPixelSafe(i, j);
          modelInput[pixelIndex] = pixel.r / 255.0;
          modelInput[pixelIndex + 1] = pixel.g / 255.0;
          modelInput[pixelIndex + 2] = pixel.b / 255.0;
          pixelIndex += 3;
        }
      }

      return modelInput;
    } catch (e) {
      print('its the convert function;');
      print(e);
      return Float32List(3);
    }
  }

  void processInferenceResults(List<dynamic> output) {
    // Process the inference output to get the labels and their coordinates
    List<Map<String, dynamic>> labels = [];
    for (dynamic label in output) {
      String text = label['label'];
      double confidence = label['confidence'];
      Map<String, dynamic> coordinates = label['rect'];
      // Check if the label is "ball" or "hoop"
      if (text == "ball" || text == "hoop") {
        labels.add({
          'text': text,
          'confidence': confidence,
          'coordinates': coordinates,
        });
      }
    }
    if (labels.isEmpty) {
      // No recognitions found, do nothing
      return;
    }
    // Do something with the filtered labels
    // ...
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

        //await controller.startVideoRecording();
      }
    } catch (e) {
      print(e);
    }
  }

  img.Image resizeImageTo32(img.Image originalImage) {
    // Print original image dimensions
    print(
        'Original image dimensions: ${originalImage.width} x ${originalImage.height}');

    // Calculate new dimensions as before
    bool isWidthSmaller = originalImage.width < originalImage.height;
    int newWidth;
    int newHeight;

    if (isWidthSmaller) {
      newWidth = 32;
      newHeight =
          (originalImage.height / originalImage.width * newWidth).round();
    } else {
      newHeight = 32;
      newWidth =
          (originalImage.width / originalImage.height * newHeight).round();
    }

    // Print new image dimensions
    print('Expected image dimensions: $newWidth x $newHeight');

    // Resize image
    img.Image resizedImage =
        img.copyResize(originalImage, width: newWidth, height: newHeight);

    // Print resized image dimensions (should be the same as expected)
    print(
        'Resized image dimensions: ${resizedImage.width} x ${resizedImage.height}');

    return resizedImage;
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
      img.Image Rimage = img.copyRotate(image, angle: 90);
      //_saveImage(Rimage.data);
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

class ImageUtils {
  /// Converts a [CameraImage] in YUV420 format to [imageLib.Image] in RGB format
  static img.Image convertYUV420ToImage(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;

    final int uvRowStride = cameraImage.planes[1].bytesPerRow;
    final int uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

    final image = img.Image(width: width, height: height);

    for (int w = 0; w < width; w++) {
      for (int h = 0; h < height; h++) {
        final int uvIndex =
            uvPixelStride * (w / 2).floor() + uvRowStride * (h / 2).floor();
        final int index = h * width + w;

        final y = cameraImage.planes[0].bytes[index];
        final u = cameraImage.planes[1].bytes[uvIndex];
        final v = cameraImage.planes[2].bytes[uvIndex];

        image.setPixelIndex(w, h, yuv2rgb(y, u, v));
      }
    }
    return image;
  }

  static int yuv2rgb(int y, int u, int v) {
    int r = (y + v * 1436 / 1024 - 179).round();
    int g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91).round();
    int b = (y + u * 1814 / 1024 - 227).round();

    r = r.clamp(0, 255);
    g = g.clamp(0, 255);
    b = b.clamp(0, 255);

    return 0xff000000 |
        ((b << 16) & 0xff0000) |
        ((g << 8) & 0xff00) |
        (r & 0xff);
  }
}
