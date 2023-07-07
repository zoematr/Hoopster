import 'dart:ffi';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hoopster/PermanentStorage.dart';
import 'package:hoopster/screens/recording_screen2.dart';
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
import 'output_processing.dart';

int i = 0;
late CameraImage _cameraImage;

List<BoundingBox> boxes = [];
int counter = 0;
String lastSaved = "";
String asset = 'model.tflite';
late ByteData byteData;
int Hit = 0;
int Miss = 0;
var height;
var width;
const int INPUT_SIZE = 416;
int counterImage = 0;
late double scalex;
late double scaley;

class CameraApp extends StatefulWidget {
  final tfl.Interpreter interpreter;
  const CameraApp({Key? key, required this.interpreter}) : super(key: key);
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

    _initializeControllerFuture = controller.initialize().then((_) async {
      var address = widget.interpreter.address;
      if (!mounted) {
        return;
      }
      controller.startImageStream((image) async {
        await _cameraFrameProcessing(image, address);
      });

      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            break;
          default:
            break;
        }
      }
    });
  }

  Future<void> _cameraFrameProcessing(CameraImage image, address) async {
    _cameraImage = image;
    counterImage++;

    if (counterImage % 10 == 0) {
      img.Image imago = ImageUtils.convertYUV420ToImage(image);
      imago = img.copyResizeCropSquare(imago, size: 416);
      Uint8List byteList = Uint8List.fromList(imago.getBytes());
      boxes = await compute(processCameraFrame, [byteList, address]);
    }
  }

  Future<tfl.Interpreter> loadModel() async {
    return tfl.Interpreter.fromAsset(
      'model.tflite',
      //options: tfl.InterpreterOptions()..threads = 4,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    widget.interpreter.close();
    super.dispose();
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
      }
    } catch (e) {
      print(e);
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
        body: Stack(children: [
      Container(
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
      CustomPaint(painter: RectanglePainter(boxes)),
    ]));
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

List<BoundingBox> processCameraFrame(List<dynamic> l) {
  Uint8List byteList = l[0];
  late tfl.Interpreter interpreter;

  try {
    interpreter = tfl.Interpreter.fromAddress(l[1]
        //options: tfl.InterpreterOptions()..threads = 4,
        );
  } catch (e) {
    print('Error loading model: $e');
  }

  try {
    Float32List floatList = Float32List(416 * 416 * 3);
    for (var i = 0; i < byteList.length; i++) {
      floatList[i] = byteList[i] / 255.0;
    }

    final imgReshaped = floatList.reshape([1, 416, 416, 3]);

    var outputShape = interpreter.getOutputTensor(0).shape;
    var outputType = interpreter.getOutputTensor(0).type;
    var outputBuffer = TensorBuffer.createFixedSize(outputShape, outputType);

    interpreter.run(imgReshaped, outputBuffer.getBuffer());

    var outputResult = outputBuffer.getDoubleList();
    var boxes = decodeTensor(outputResult, 0.45);
    return boxes;
  } catch (e) {
    return [];
  }
}

void processInferenceResults(List<dynamic> output) {
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
    return;
  }
}

img.Image fromFltoIM(Float32List F32l) {
  img.Image im =
      img.Image.fromBytes(width: 416, height: 416, bytes: F32l.buffer);

  return im;
}

class RectanglePainter extends CustomPainter {
  List<BoundingBox> topaint;
  RectanglePainter(this.topaint);

  @override
  void paint(Canvas canvas, size) {
    var paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (var box in boxes) {
      canvas.drawRect(
          Rect.fromLTWH(box.x, box.y, box.width, box.height), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false; // No need to repaint since the rectangle is static
  }
}
