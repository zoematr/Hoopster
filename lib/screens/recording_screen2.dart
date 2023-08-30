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
import 'package:hoopster/newStuff/detector_widget.dart';
import 'package:hoopster/screens/recording_screen2.dart';
import 'package:hoopster/statsObjects.dart';

import 'package:tflite_flutter/tflite_flutter.dart' as tfl;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import '../main.dart';
import 'home_screen.dart';
import 'output_processing.dart';

late int padSize;
int i = 0;
List<BoundingBox>? boxes = [];
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

class CameraApp extends StatefulWidget {
  double w;
  double h;
  final tfl.Interpreter interpreter;
  CameraApp(
      {Key? key, required this.interpreter, required this.h, required this.w})
      : super(key: key);
  @override
  State<CameraApp> createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  late CameraController controller;
  late Future<void> _initializeControllerFuture;
  _CameraAppState() {
    //time = DateTime.now();
  }

  String _videoPath = '';

  @override
  void initState() {
    super.initState();

    controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = controller.initialize().then((_) async {
      var address = widget.interpreter.address;
      var outputTensors = widget.interpreter.getOutputTensors();
      outputTensors.forEach((tensor) {
        _outputShapes.add(tensor.shape);
      });
      if (!mounted) {
        return;
      }
      controller.startImageStream((image) async {
        if (!StopModel) {
          await _cameraFrameProcessing(image, address);
        }
        //print(StopModel);
        if (counter % 100 == 0) {
          _cameraImage = image;
          setState(() {});
          counterImage++;
        }
        counter++;
      });
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
    if (!isprocessing) {
      isprocessing = true;
      img.Image? imago = ImageUtils3.convertCameraImageToImage(image);

      //ImageUtils2.saveImage(imagine.image, counter);

      try {
        boxes = await compute(processCameraFrame, [
          imago,
          address,
        ]);
      } catch (e) {
        print("here $e");
        isprocessing = false;
      }

      setState(() {});

      isprocessing = false;
    }
  }

  Future<tfl.Interpreter> loadModel() async {
    return tfl.Interpreter.fromAsset(
      'AssetsFolder\\detect.tflite',
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
            GestureDetector(
              child: SizedBox(child: DetectorWidget() /*CameraPreview(controller)*/),
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
                          //capture(),
                          setState(() {
                            if (tap % 2 == 0) {
                              tap++;
                              StopModel = false;
                            } else {
                              tap++;
                              StopModel == true;
                            }

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
      //CustomPaint(painter: RectanglePainter(boxes!)),
    ]));
  }
}

/*class ImageUtils {
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
}*/

class ImageUtils3 {
  static img.Image? convertCameraImageToImage(CameraImage cameraImage) {
    img.Image image;

    if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      image = convertYUV420ToImage(cameraImage);
    } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      image = convertBGRA8888ToImage(cameraImage);
    } else if (cameraImage.format.group == ImageFormatGroup.jpeg) {
      image = convertJPEGToImage(cameraImage);
    } else if (cameraImage.format.group == ImageFormatGroup.nv21) {
      image = convertNV21ToImage(cameraImage);
    } else {
      return null;
    }

    return image;
  }

  static img.Image convertYUV420ToImage(CameraImage cameraImage) {
    final width = cameraImage.width;
    final height = cameraImage.height;

    final uvRowStride = cameraImage.planes[1].bytesPerRow;
    final uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

    final yPlane = cameraImage.planes[0].bytes;
    final uPlane = cameraImage.planes[1].bytes;
    final vPlane = cameraImage.planes[2].bytes;

    final image = img.Image(width: width, height: height);

    var uvIndex = 0;

    for (var y = 0; y < height; y++) {
      var pY = y * width;
      var pUV = uvIndex;

      for (var x = 0; x < width; x++) {
        final yValue = yPlane[pY];
        final uValue = uPlane[pUV];
        final vValue = vPlane[pUV];

        final r = yValue + 1.402 * (vValue - 128);
        final g =
            yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128);
        final b = yValue + 1.772 * (uValue - 128);

        image.setPixelRgba(x, y, r.toInt(), g.toInt(), b.toInt(), 255);

        pY++;
        if (x % 2 == 1 && uvPixelStride == 2) {
          pUV += uvPixelStride;
        } else if (x % 2 == 1 && uvPixelStride == 1) {
          pUV++;
        }
      }

      if (y % 2 == 1) {
        uvIndex += uvRowStride;
      }
    }
    return image;
  }

  static img.Image convertBGRA8888ToImage(CameraImage cameraImage) {
    // Extract the bytes from the CameraImage
    final bytes = cameraImage.planes[0].bytes;

    // Create a new Image instance
    final image = img.Image.fromBytes(
      width: cameraImage.width,
      height: cameraImage.height,
      bytes: bytes.buffer,
      order: img.ChannelOrder.rgba,
    );

    return image;
  }

  static img.Image convertJPEGToImage(CameraImage cameraImage) {
    // Extract the bytes from the CameraImage
    final bytes = cameraImage.planes[0].bytes;

    // Create a new Image instance from the JPEG bytes
    final image = img.decodeImage(bytes);

    return image!;
  }

  static img.Image convertNV21ToImage(CameraImage cameraImage) {
    // Extract the bytes from the CameraImage
    final yuvBytes = cameraImage.planes[0].bytes;
    final vuBytes = cameraImage.planes[1].bytes;

    // Create a new Image instance
    final image = img.Image(
      width: cameraImage.width,
      height: cameraImage.height,
    );

    // Convert NV21 to RGB
    /* convertNV21ToRGB(
    yuvBytes,
    vuBytes,
    cameraImage.width,
    cameraImage.height,
    image,
  );*/

    return image;
  }

  void convertNV21ToRGB(Uint8List yuvBytes, Uint8List vuBytes, int width,
      int height, img.Image image) {
    // Conversion logic from NV21 to RGB
    // ...

    // Example conversion logic using the `imageLib` package
    // This is just a placeholder and may not be the most efficient method
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final yIndex = y * width + x;
        final uvIndex = (y ~/ 2) * (width ~/ 2) + (x ~/ 2);

        final yValue = yuvBytes[yIndex];
        final uValue = vuBytes[uvIndex * 2];
        final vValue = vuBytes[uvIndex * 2 + 1];

        // Convert YUV to RGB
        final r = yValue + 1.402 * (vValue - 128);
        final g =
            yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128);
        final b = yValue + 1.772 * (uValue - 128);

        // Set the RGB pixel values in the Image instance
        image.setPixelRgba(x, y, r.toInt(), g.toInt(), b.toInt(), 255);
      }
    }
  }

  img.Image applyExifRotation(img.Image image, int exifRotation) {
    if (exifRotation == 1) {
      return img.copyRotate(image, angle: 0);
    } else if (exifRotation == 3) {
      return img.copyRotate(image, angle: 180);
    } else if (exifRotation == 6) {
      return img.copyRotate(image, angle: 90);
    } else if (exifRotation == 8) {
      return img.copyRotate(image, angle: 270);
    }

    return image;
  }
}

class ImageUtils2 {
  static img.Image convertCameraImage(CameraImage cameraImage) {
    if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      return rgbToImage(
          cameraImage.width, cameraImage.height, Gyuv420ToRgb(cameraImage));
    } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      return convertBGRA8888ToImage(cameraImage);
    } else {
      return img.Image.empty();
    }
  }

  static List<int> Gyuv420ToRgb(CameraImage image) {
    final int width = image.width;
    final int height = image.height;

    final int size = width * height;

    final List<int> yData = image.planes[0].bytes;
    final List<int> uData = image.planes[1].bytes;
    final List<int> vData = image.planes[2].bytes;

    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel!.toInt();

    final List<int> rgbData = List<int>.filled(size * 3, 0);

    for (int j = 0; j < height; j++) {
      for (int i = 0; i < width; i++) {
        final int yPos = j * width + i;
        final int uvPos = (j ~/ 2) * uvRowStride + (i ~/ 2) * uvPixelStride;

        final int y = yData[yPos];
        final int u = uData[uvPos] - 128;
        final int v = vData[uvPos] - 128;

        int r = (y + 1.402 * v).round().clamp(0, 255).toInt();
        int g = (y - 0.344136 * u - 0.714136 * v).round().clamp(0, 255).toInt();
        int b = (y + 1.772 * u).round().clamp(0, 255).toInt();

        final int pos = yPos * 3;
        rgbData[pos] = r;
        rgbData[pos + 1] = g;
        rgbData[pos + 2] = b;
      }
    }

    return rgbData;
  }

  static img.Image rgbToImage(int width, int height, List<int> rgbData) {
    img.Image image = img.Image(width: width, height: height);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int pos = (y * width + x) * 3;
        int r = rgbData[pos];
        int g = rgbData[pos + 1];
        int b = rgbData[pos + 2];
        image.setPixelRgba(x, y, r, g, b, 255);
      }
    }
    return img.copyRotate(image, angle: 90);
  }

  static img.Image convertBGRA8888ToImage(CameraImage cameraImage) {
    img.Image imag = img.Image.fromBytes(
        width: cameraImage.width,
        height: cameraImage.height,
        bytes: cameraImage.planes[0].bytes.buffer);
    return imag;
  }

  /// Converts a [CameraImage] in YUV420 format to [imageLib.Image] in RGB format
  static img.Image convertYUV420ToImage(CameraImage cameraImage) {
    final int width = cameraImage.width;
    final int height = cameraImage.height;

    final int uvRowStride = cameraImage.planes[1].bytesPerRow;
    final int uvPixelStride = cameraImage.planes[1].bytesPerPixel!.toInt();

    //final image = img.Image(width, height);
    final image = img.Image(width: width, height: height);

    for (int w = 0; w < width; w++) {
      for (int h = 0; h < height; h++) {
        final int uvIndex =
            uvPixelStride * (w / 2).floor() + uvRowStride * (h / 2).floor();
        final int index = h * width + w;

        final y = cameraImage.planes[0].bytes[index];
        final u = cameraImage.planes[1].bytes[uvIndex];
        final v = cameraImage.planes[2].bytes[uvIndex];

        image.setPixelIndex(w, h, ImageUtils2.yuv2rgb(y, u, v));
      }
    }
    return image;
  }

  /// Convert a single YUV pixel to RGB
  static int yuv2rgb(int y, int u, int v) {
    // Convert yuv pixel to rgb
    int r = (y + v * 1436 / 1024 - 179).round();
    int g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91).round();
    int b = (y + u * 1814 / 1024 - 227).round();

    // Clipping RGB values to be inside boundaries [ 0 , 255 ]
    r = r.clamp(0, 255);
    g = g.clamp(0, 255);
    b = b.clamp(0, 255);

    return 0xff000000 |
        ((b << 16) & 0xff0000) |
        ((g << 8) & 0xff00) |
        (r & 0xff);
  }

  static void saveImage(img.Image image, [int i = 0]) async {
    List<int> jpeg = img.JpegEncoder().encode(image);
    final appDir = await getTemporaryDirectory();
    final appPath = appDir.path;
    //final fileOnDevice = File('$appPath/out$i.jpg');
    ImageGallerySaver.saveImage(Uint8List.fromList(jpeg));
    //await fileOnDevice.writeAsBytes(jpeg, flush: true);
    print('Saved $appPath/out$i.jpg');
  }
}

List<BoundingBox>? processCameraFrame(List<dynamic> l) {
  //print('weve come too far to give up now');
  img.Image inputImage = l[0];
  late tfl.Interpreter interpreter;

  try {
    interpreter = tfl.Interpreter.fromAddress(l[1]);
  } catch (e) {
    print('Error loading model: $e');
  }

  final imageInput = img.copyResize(
    inputImage,
    width: 300,
    height: 300,
  );

  // Creating matrix representation, [300, 300, 3]
  final imageMatrix = List.generate(
    imageInput.height,
    (y) => List.generate(
      imageInput.width,
      (x) {
        final pixel = imageInput.getPixel(x, y);
        return Uint8List.fromList(
            [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()]);
      },
    ),
  );

  final output = _runInference(imageMatrix, interpreter);

  // Location
  final locationsRaw = output.first.first as List<List<num>>;
  //print(locationsRaw);

  final List<Rect> locations = locationsRaw
      .map((list) => list.map((value) => (value * 300)).toList())
      .map((rect) => Rect.fromLTRB(rect[1].toDouble(), rect[0].toDouble(),
          rect[3].toDouble(), rect[2].toDouble()))
      .toList();

  final classesRaw = output.elementAt(1).first as List<double>;
  final classes = classesRaw.map((value) => value.toInt()).toList();
  final scores = output.elementAt(2).first as List<double>;

  final numberOfDetectionsRaw = output.last.first as double;
  final numberOfDetections = numberOfDetectionsRaw.toInt();
  print(numberOfDetections);
  try {
    List<BoundingBox> recognitions = [];
    for (int i = 0; i < numberOfDetections; i++) {
      // Prediction score
      var score = scores[i];
      // Label string

      var labela = labels[classes[i]];
      if (score > 0.8 && labela=="sports ball") {
        //print(label);
        //print(score);
      }
    }
  } catch (e) {
   /* print("here it fucking goes $e");
    print("the index is $i");
    print(scores[i]);
    print(labels[i]);*/
  }
}

/// Object detection main function
List<List<Object>> _runInference(
    List<List<List<num>>> imageMatrix, tfl.Interpreter interpreter) {
  // Set input tensor [1, 300, 300, 3]
  final input = [imageMatrix];

  // Set output tensor
  // Locations: [1, 10, 4]
  // Classes: [1, 10],
  // Scores: [1, 10],
  // Number of detections: [1]
  final output = {
    0: [List<List<num>>.filled(10, List<num>.filled(4, 0))],
    1: [List<num>.filled(10, 0)],
    2: [List<num>.filled(10, 0)],
    3: [0.0],
  };
  try {
    interpreter.runForMultipleInputs([input], output);
    print('runs interpreter');
  } catch (e) {
    //print(imageMatrix.first.first.first.runtimeType);
    print('Error during inference: $e');
  }

  return output.values.toList();
}

class RectanglePainter extends CustomPainter {
  List<BoundingBox> boxes;
  RectanglePainter(this.boxes);

  @override
  void paint(Canvas canvas, size) {
    var paint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (var box in boxes) {
      canvas.drawRect(
          Rect.fromLTWH(box.x, box.y, box.width, box.height), paint);
      //print(labels[box.classId]);
    }
  }

  @override
  bool shouldRepaint(RectanglePainter oldDelegate) {
    //return torepaint;
    // Repaint if the old boxes are not the same as the new ones
    return oldDelegate.boxes != this.boxes;
  }
}

/*void NormalizeBasketCoor(List<List<double>> coor) {
  List<List<double>> ret = [];

  ret.add(coor[0]);

  ret.add([coor[1][0] - getDistance(coor[0][0], coor[1][0]), coor[0][1]]);
}

double getDistance(double a, double b) {
  double d = 0;
  d = max(a, b) - min(a, b);
  return d;
}*/

List<List<double>> normalizeToRectangle(List<List<double>> coor) {
  Point p1 = Point(coor[0][0], coor[0][1]);
  Point p2 = Point(coor[1][0], coor[1][1]);
  Point p3 = Point(coor[2][0], coor[2][1]);
  Point p4 = Point(coor[3][0], coor[3][1]);
  // Calculate the distances between the points
  final d12 = _distanceBetweenPoints(p1, p2);
  final d13 = _distanceBetweenPoints(p1, p3);
  final d14 = _distanceBetweenPoints(p1, p4);

  // Find the shortest and longest distances
  final minDistance = min(min(d12, d13), d14);
  final maxDistance = max(max(d12, d13), d14);

  // Determine the diagonal points based on the shortest and longest distances
  Point diagonal1, diagonal2;
  if (minDistance == d12) {
    diagonal1 = p2;
    diagonal2 = d13 < d14 ? p3 : p4;
  } else if (minDistance == d13) {
    diagonal1 = p3;
    diagonal2 = d12 < d14 ? p2 : p4;
  } else {
    diagonal1 = p4;
    diagonal2 = d12 < d13 ? p2 : p3;
  }

  // Calculate the new points to form a rectangle
  final normalizedP2 =
      _calculateNormalizedPoint(p1, diagonal1, diagonal2, maxDistance);
  final normalizedP3 =
      _calculateNormalizedPoint(p1, diagonal2, diagonal1, maxDistance);
  final normalizedP4 =
      _calculateNormalizedPoint(p1, diagonal1, diagonal2, minDistance);

  return [
    [p1.x.toDouble(), p1.y.toDouble()],
    [normalizedP2.x.toDouble(), normalizedP2.y.toDouble()],
    [normalizedP3.x.toDouble(), normalizedP3.y.toDouble()],
    [normalizedP4.x.toDouble(), normalizedP4.y.toDouble()]
  ];
}

double _distanceBetweenPoints(Point p1, Point p2) {
  final dx = p2.x - p1.x;
  final dy = p2.y - p1.y;
  return sqrt(dx * dx + dy * dy);
}

Point _calculateNormalizedPoint(
    Point reference, Point diagonal1, Point diagonal2, double targetDistance) {
  final dx = diagonal1.x - reference.x;
  final dy = diagonal1.y - reference.y;
  final currentDistance = sqrt(dx * dx + dy * dy);
  final scaleFactor = targetDistance / currentDistance;
  final normalizedX = reference.x + dx * scaleFactor;
  final normalizedY = reference.y + dy * scaleFactor;
  return Point(normalizedX, normalizedY);
}

void ShotLogicHandler(
    List<DateTime> Time, List<BoundingBox> BallBoxes, List<List<double>> Hoop) {
  if (Time.length >= 3) {
    bool _made = false;
    List<double> lx = [];
    List<double> ly = [];
    List<double> ti = [];
    List<List<double>> cr = [];
    for (int i = 0; i < BallBoxes.length; i++) {
      cr.add([BallBoxes[i].x, BallBoxes[i].y]);
      lx.add(BallBoxes[i].x);
      ly.add(BallBoxes[i].y);
      ti.add(fromDateTodouble(Time[i]));
    }

    bool _isIt = ParabolaChecker([time, lx, ly]);

    if (_isIt) {
      _made = ShotChecker(cr, Hoop);
    }
    if (_made) {
      Hit++;
    } else {
      Miss++;
    }
  }
}

double fromDateTodouble(DateTime d) {
  double t = 0;
  String s = "$d.minutes.$d.millisecond";
  t = double.parse(s);
  return t;
}

Future<List<String>> loadLabelsFromFile() async {
  String filePath = 'AssetsFolder\\labelmap.txt';

  try {
    File file = File(filePath);
    List<String> labels = await file.readAsLines();
    return labels;
  } catch (e) {
    print('didnt work because: $e');
    return [];
  }
}
